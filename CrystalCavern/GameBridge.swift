//
//  GameBridge.swift
//
//  ゲーム（JavaScript）からの呼び出しを受け取り、アプリ側の機能につなぎます。
//  受け取るのは次のものだけです。
//
//    ccHaptic  { kind: "tap" | "buy" | "orb" | "seam" | "rebirth" }
//    ccAds     { reward: "skip" | "boost" | "orb" | "core" | "back" | "visit" | "exp" }
//    ccAds     { query: true }  いま見せられる広告があるか教えてほしい（1.3）
//    ccIdle    { rate: Int, paused: Bool, fullAfterSeconds: Int,
//                expeditionAfterSeconds: Int }   採掘隊が帰るまでの秒数（1.4）。0 なら出ていない
//    ccReview  {}             星の評価のお願い（1.4）。出すかどうかは iOS が決める
//    ccNotify  {}             メニューの「お知らせの設定」が押された
//    ccNotify  { query: true } 通知の許可がまだ未回答か教えてほしい（1.3）
//    ccNotify  { ask: true }   案内のカードで「受け取る」が押された（1.3）
//    ccPrivacy {}             同意を変える入口を見せるべきか教えてほしい
//    ccPrivacy { open: true } メニューの「プライバシー設定」が押された
//
//  広告の返事は window.CCAds.grant(id) / window.CCAds.fail(id) で、
//  広告の用意ができたかは window.CCAds.ready(真偽)、画面に出たことは window.CCAds.shown() で、
//  プライバシー設定のボタンを出すかどうかは window.CCPrivacy.set(真偽) で、
//  通知の許可の状態は window.CCNotify.status('notDetermined' など) で返します。
//

import UIKit
import WebKit
import StoreKit

final class GameBridge: NSObject, WKScriptMessageHandler, WKNavigationDelegate {

    weak var webView: WKWebView?

    /// いま画面に出ているゲームとの窓口。
    /// 同意の確認が終わったときに、アプリ側からゲームへ知らせるために使います。
    static weak var current: GameBridge?

    override init() {
        super.init()
        GameBridge.current = self
    }

    /// 広告を出している最中かどうか。
    /// 全画面の広告が出ると WebView は「隠れた」と判断して ccIdle を送ってきますが、
    /// 遊んでいる人はまだそこにいます。留守の予約をする場面ではありません。
    private var adOnScreen = false

    // MARK: - JavaScript からの受け口

    func userContentController(_ controller: WKUserContentController,
                               didReceive message: WKScriptMessage) {
        let body = message.body as? [String: Any] ?? [:]

        switch message.name {

        case "ccHaptic":
            let kind = body["kind"] as? String ?? "tap"
            Haptics.shared.play(kind)

        case "ccAds":
            if body["query"] as? Bool == true {
                sendAdState(ready: AdsManager.shared.isReady)
                return
            }
            guard let reward = body["reward"] as? String else { return }
            showRewardedAd(for: reward)

        case "ccIdle":
            guard !adOnScreen else { return }
            let rate = body["rate"] as? Int ?? 0
            let paused = body["paused"] as? Bool ?? false
            let seconds = body["fullAfterSeconds"] as? Int ?? 8 * 3600
            NotificationManager.shared.scheduleCaveFull(
                afterSeconds: seconds, perSecond: rate, paused: paused)
            // 採掘隊（1.4）。出ている隊のうち、いちばん早く帰る時刻に1回だけ。
            let exp = body["expeditionAfterSeconds"] as? Int ?? 0
            NotificationManager.shared.scheduleExpedition(afterSeconds: exp)

        case "ccReview":
            // Apple 標準の「このアプリを評価」の小さな画面。
            // 本当に出すかどうか（1年に3回まで）は iOS が決めます。
            requestReview()

        case "ccNotify":
            if body["query"] as? Bool == true {
                sendNotifyStatus()
            } else if body["ask"] as? Bool == true {
                // 案内のカードで「受け取る」を押した人にだけ、iOS の許可の画面を出す。
                // すでに答えている人には何もしない（設定アプリも開かない）。
                NotificationManager.shared.requestIfUndetermined { self.sendNotifyStatus() }
            } else {
                NotificationManager.shared.promptOrOpenSettings()
            }

        case "ccPrivacy":
            if body["open"] as? Bool == true {
                ConsentManager.shared.presentPrivacyOptions()
            } else {
                sendPrivacyStatus()
            }

        default:
            break
        }
    }

    // MARK: - 広告

    private func showRewardedAd(for reward: String) {
        adOnScreen = true
        AdsManager.shared.showRewarded { granted in
            self.adOnScreen = false
            // JavaScript 側は45秒で自分から諦めるので、
            // 返事が遅れても固まることはありません。
            self.answer(reward: reward, granted: granted)
        }
    }

    private func answer(reward: String, granted: Bool) {
        // 念のためエスケープ。id は英数字だけですが、素通しにはしない。
        let safe = reward.replacingOccurrences(of: "'", with: "")
                         .replacingOccurrences(of: "\\", with: "")
        let fn = granted ? "grant" : "fail"
        let js = "window.CCAds && window.CCAds.\(fn)('\(safe)');"
        DispatchQueue.main.async {
            self.webView?.evaluateJavaScript(js, completionHandler: nil)
        }
    }

    /// 広告の用意ができているかをゲームへ伝えます。
    func sendAdState(ready: Bool) {
        let js = "window.CCAds && window.CCAds.ready && window.CCAds.ready(\(ready ? "true" : "false"));"
        DispatchQueue.main.async {
            self.webView?.evaluateJavaScript(js, completionHandler: nil)
        }
    }

    /// 広告が画面に出たことをゲームへ伝えます。
    func sendAdShown() {
        let js = "window.CCAds && window.CCAds.shown && window.CCAds.shown();"
        DispatchQueue.main.async {
            self.webView?.evaluateJavaScript(js, completionHandler: nil)
        }
    }

    // MARK: - 評価のお願い（1.4）

    private func requestReview() {
        Task { @MainActor in
            guard let scene = UIApplication.shared.connectedScenes
                    .compactMap({ $0 as? UIWindowScene })
                    .first(where: { $0.activationState == .foregroundActive }) else { return }
            // iOS 16 から使える書き方。このアプリは iOS 16 以上なので、これだけで足ります。
            AppStore.requestReview(in: scene)
        }
    }

    // MARK: - プライバシー設定

    /// メニューに「プライバシー設定」のボタンを出すかどうかをゲームへ伝えます。
    /// EU・イギリス・スイスの人にだけ出ます。
    func sendPrivacyStatus() {
        let on = ConsentManager.shared.privacyOptionsRequired ? "true" : "false"
        let js = "window.CCPrivacy && window.CCPrivacy.set(\(on));"
        webView?.evaluateJavaScript(js, completionHandler: nil)
    }

    // MARK: - 通知の許可の状態

    /// 通知の許可がどうなっているかをゲームへ伝えます。
    /// ゲームは "notDetermined"（まだ答えていない）のときだけ案内のカードを出します。
    func sendNotifyStatus() {
        NotificationManager.shared.status { state in
            let js = "window.CCNotify && window.CCNotify.status('\(state)');"
            self.webView?.evaluateJavaScript(js, completionHandler: nil)
        }
    }

    // MARK: - 画面遷移の制御

    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {

        guard let url = navigationAction.request.url else {
            decisionHandler(.allow); return
        }

        // 同梱ファイルの中の移動だけ、この WebView で行う
        if url.isFileURL {
            decisionHandler(.allow); return
        }

        // 外部リンク（サポートページ、共有先など）は Safari に渡す。
        // アプリの中でウェブを開き続けると、それこそ「ウェブの再包装」になる。
        if url.scheme == "http" || url.scheme == "https" || url.scheme == "mailto" {
            UIApplication.shared.open(url)
        }
        decisionHandler(.cancel)
    }
}
