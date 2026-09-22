//
//  GameBridge.swift
//
//  ゲーム（JavaScript）からの呼び出しを受け取り、アプリ側の機能につなぎます。
//  受け取るのは3種類だけです。
//
//    ccHaptic  { kind: "tap" | "buy" | "orb" | "seam" | "rebirth" }
//    ccAds     { reward: "skip" | "boost" | "orb" | "core" }
//    ccIdle    { rate: Int, paused: Bool, fullAfterSeconds: Int }
//    ccNotify  {}   メニューの「お知らせの設定」が押された
//
//  返事は window.CCAds.grant(id) / window.CCAds.fail(id) で返します。
//

import UIKit
import WebKit

final class GameBridge: NSObject, WKScriptMessageHandler, WKNavigationDelegate {

    weak var webView: WKWebView?

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
            guard let reward = body["reward"] as? String else { return }
            showRewardedAd(for: reward)

        case "ccIdle":
            guard !adOnScreen else { return }
            let rate = body["rate"] as? Int ?? 0
            let paused = body["paused"] as? Bool ?? false
            let seconds = body["fullAfterSeconds"] as? Int ?? 8 * 3600
            NotificationManager.shared.scheduleCaveFull(
                afterSeconds: seconds, perSecond: rate, paused: paused)

        case "ccNotify":
            NotificationManager.shared.promptOrOpenSettings()

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
