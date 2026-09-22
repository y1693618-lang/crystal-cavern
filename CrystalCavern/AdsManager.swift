//
//  AdsManager.swift
//
//  AdMob のリワード動画を1本だけ抱えておき、求められたら見せます。
//  広告はゲームの進行に必須ではありません。見なくても最後まで遊べます。
//
//  ⚠ 下の adUnitID を自分の広告ユニット ID に差し替えてください。
//    いまの値は Google が公開しているテスト用の ID です。
//    テスト ID のまま公開すると収益は発生せず、規約違反にもなります。
//

import UIKit
import GoogleMobileAds
import AppTrackingTransparency

@MainActor
final class AdsManager: NSObject {

    static let shared = AdsManager()
    private override init() { super.init() }

    // MARK: - 差し替える場所

    /// Google のテスト用リワード広告 ID。自分のものに置き換えること。
    private let adUnitID = "ca-app-pub-3940256099942544/1712485313"

    // MARK: - 中身

    private var rewarded: RewardedAd?
    private var isLoading = false
    private var completion: ((Bool) -> Void)?
    private var earned = false

    /// 読み込みに失敗し続けたときに間を空けるための回数
    private var failures = 0

    // MARK: - 読み込み

    func preload() {
        guard rewarded == nil, !isLoading else { return }
        isLoading = true

        Task {
            do {
                let ad = try await RewardedAd.load(with: adUnitID, request: Request())
                ad.fullScreenContentDelegate = self
                self.rewarded = ad
                self.failures = 0
            } catch {
                // 在庫がない、通信がない、などは普通に起きる。
                // 黙って諦め、少し待ってからもう一度だけ試す。
                self.failures += 1
                let wait = min(60, 5 * self.failures)
                Task {
                    try? await Task.sleep(nanoseconds: UInt64(wait) * 1_000_000_000)
                    self.preload()
                }
            }
            self.isLoading = false
        }
    }

    // MARK: - 表示

    /// 広告を出し、報酬を与えてよいかどうかを返します。
    /// 用意できていない・途中で閉じられた場合は false。
    func showRewarded(_ done: @escaping (Bool) -> Void) {
        guard let ad = rewarded,
              let root = Self.topViewController() else {
            done(false)
            preload()          // 次に備えて読み込んでおく
            return
        }

        completion = done
        earned = false
        rewarded = nil         // 一度見せた広告は使い回せない

        ad.present(from: root) { [weak self] in
            // 報酬の条件を満たした（最後まで見た）
            self?.earned = true
        }
    }

    private func finish() {
        let ok = earned
        let cb = completion
        completion = nil
        earned = false
        preload()
        cb?(ok)
    }

    // MARK: - 追跡の許可

    /// 許可を求める前に、何のためかを画面で説明します。
    /// いきなりシステムの確認画面を出すと、意味が分からないまま拒否されがちで、
    /// 一度拒否されると設定から辿らない限り二度と聞けません。
    func requestTrackingIfNeeded() async {
        guard ATTrackingManager.trackingAuthorizationStatus == .notDetermined else {
            preload(); return
        }

        let agreed = await Self.showPrePrompt()
        guard agreed else {
            // ここで「あとで」を選んだ場合、システムの確認画面は出しません。
            // 次の起動でもう一度説明します。
            preload(); return
        }

        _ = await ATTrackingManager.requestTrackingAuthorization()
        preload()
    }

    /// 事前説明。日本語と英語だけ用意し、それ以外の言語では英語を出します。
    private static func showPrePrompt() async -> Bool {
        await withCheckedContinuation { continuation in
            guard let root = topViewController() else {
                continuation.resume(returning: false); return
            }

            let ja = Locale.preferredLanguages.first?.hasPrefix("ja") ?? false

            let alert = UIAlertController(
                title: ja ? "広告について" : "About the ads",
                message: ja
                    ? "このゲームは無料で、遊ぶのに広告を見る必要はありません。\n\n"
                      + "ボーナスを受け取るときだけ動画が流れます。次の画面で許可をいただけると、"
                      + "表示される広告があなたに合ったものになり、そのぶん開発を続けやすくなります。\n\n"
                      + "許可しなくても、ゲームの内容は何ひとつ変わりません。"
                    : "This game is free, and you never have to watch an advert to play it.\n\n"
                      + "A video only plays when you claim a bonus. Allowing tracking on the next "
                      + "screen makes those adverts more relevant, which helps keep this game going.\n\n"
                      + "Nothing about the game changes if you decline.",
                preferredStyle: .alert)

            alert.addAction(UIAlertAction(
                title: ja ? "あとで" : "Not now", style: .cancel) { _ in
                    continuation.resume(returning: false)
                })
            alert.addAction(UIAlertAction(
                title: ja ? "続ける" : "Continue", style: .default) { _ in
                    continuation.resume(returning: true)
                })

            root.present(alert, animated: true)
        }
    }

    // MARK: - 表示元の画面を探す

    static func topViewController() -> UIViewController? {
        let scene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }

        var top = scene?.windows.first(where: \.isKeyWindow)?.rootViewController
        while let presented = top?.presentedViewController {
            top = presented
        }
        return top
    }
}

// MARK: - 全画面広告の開閉

extension AdsManager: FullScreenContentDelegate {

    func ad(_ ad: FullScreenPresentingAd,
            didFailToPresentFullScreenContentWithError error: Error) {
        finish()
    }

    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        finish()
    }
}
