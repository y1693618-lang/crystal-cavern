//
//  AdsManager.swift
//
//  AdMob のリワード動画を1本だけ抱えておき、求められたら見せます。
//  広告はゲームの進行に必須ではありません。見なくても最後まで遊べます。
//
//  ⚠ 本物の広告 ID が入っています。自分でボーナスのボタンを押さないでください。
//    自分の広告を見たり押したりすると、AdMob のアカウントが止まることがあります。
//

import UIKit
import GoogleMobileAds
import AppTrackingTransparency

@MainActor
final class AdsManager: NSObject {

    static let shared = AdsManager()
    private override init() { super.init() }

    // MARK: - 広告ユニット

    /// リワード広告の ID（本番）。
    /// AdMob → アプリ → 結晶洞窟 → 広告ユニット の「結晶洞窟 リワード」です。
    /// テスト用に戻すときの値： ca-app-pub-3940256099942544/1712485313
    private let adUnitID = "ca-app-pub-2566692752938685/5956248220"

    // MARK: - 中身

    private var rewarded: RewardedAd?
    private var isLoading = false
    private var completion: ((Bool) -> Void)?
    private var earned = false

    /// 読み込みに失敗し続けたときに間を空けるための回数
    private var failures = 0

    /// 広告の SDK を動かし始めたか。追跡許可の返事が出るまでは動かしません。
    private var started = false
    /// 起動時の手続き（同意の確認 → 追跡許可 → 広告の開始）の状態
    private var preparing = false
    private var prepared = false

    // MARK: - 起動時の手続き

    /// 起動時に一度だけ、次の順で進めます。
    ///
    ///   1. EU・イギリス向けの同意確認（対象外の地域では何も出ない）
    ///   2. iOS の追跡許可（システムの確認画面）
    ///   3. 広告の SDK を動かし始める
    ///
    /// ── 2026年9月の差し戻しを受けて変えたこと ──
    ///
    /// ・自前の説明画面をやめました。そこに「あとで」ボタンがあり、
    ///   押すとシステムの確認画面が出ないまま終わっていました。
    ///   Apple は、確認を先送りできる事前画面を認めていません。
    ///   説明は、システムの確認画面の中の文（InfoPlist.strings）が担います。
    ///
    /// ・アプリが前面で操作できる状態（active）のときにだけ尋ねます。
    ///   それ以外の状態で尋ねると、iOS は画面を出さずに黙って終わります。
    ///   画面が出なかったときは、次に前面へ戻ってきたときにやり直します。
    ///
    /// ・広告の SDK は、追跡許可の返事が出てから動かし始めます。
    ///   Apple は「追跡に使えるデータを集める前に尋ねること」を求めています。
    ///
    /// 何度呼んでも構いません。済んでいれば何もしません。
    func prepareIfNeeded() async {
        guard !prepared, !preparing else { return }
        preparing = true
        defer { preparing = false }

        // 画面が出そろうのを少しだけ待つ
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        guard UIApplication.shared.applicationState == .active else { return }

        await ConsentManager.shared.gather()
        guard UIApplication.shared.applicationState == .active else { return }

        if ATTrackingManager.trackingAuthorizationStatus == .notDetermined {
            _ = await ATTrackingManager.requestTrackingAuthorization()
        }

        // まだ「未回答」のまま＝確認画面が出なかった。次の機会にもう一度。
        // （本体の設定で追跡の要求そのものを切っている人は、最初から
        //   「拒否」扱いなので、ここは素通りして広告の開始へ進みます）
        guard ATTrackingManager.trackingAuthorizationStatus != .notDetermined else { return }

        prepared = true
        start()
    }

    private func start() {
        guard !started else { return }
        started = true
        MobileAds.shared.start { [weak self] _ in
            Task { @MainActor in self?.preload() }
        }
    }

    // MARK: - 読み込み

    func preload() {
        guard started, rewarded == nil, !isLoading else { return }
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

    // MARK: - 表示元の画面を探す

    static func topViewController() -> UIViewController? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        // 前面で操作中の画面を優先し、見つからなければ最初の画面を使う
        let scene = scenes.first { $0.activationState == .foregroundActive } ?? scenes.first

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
