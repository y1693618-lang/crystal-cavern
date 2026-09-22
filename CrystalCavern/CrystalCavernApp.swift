//
//  CrystalCavernApp.swift
//  結晶洞窟 — iOS
//
//  アプリの入口。画面はひとつだけで、中身は同梱した game.html です。
//  ネットワークには一切つながりません（広告を除く）。
//

import SwiftUI

@main
struct CrystalCavernApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            GameScreen()
                // ゲーム側が safe-area を自前で扱うので、画面いっぱいに広げる
                .ignoresSafeArea()
                // 洞窟の画面に合わせて、ステータスバーの文字を白にする
                .preferredColorScheme(.dark)
                .onAppear {
                    // 起動して少し経ってから、広告まわりの確認をまとめて行う。
                    // いきなり出すと「何の話か分からないまま拒否」になりやすい。
                    Task {
                        try? await Task.sleep(nanoseconds: 2_000_000_000)

                        // 1. EU・イギリス向けの同意確認（対象外の地域では何も起きない）
                        //    ビルドが通らないときは、この1行を消してよい。
                        await ConsentManager.shared.gather()

                        // 2. iOS の追跡許可（事前に自前の説明を出してから）
                        await AdsManager.shared.requestTrackingIfNeeded()
                    }
                }
        }
        .onChange(of: scenePhase) { _, phase in
            // 前面に戻ってきたら、予約していた通知は役目を終えている
            if phase == .active {
                NotificationManager.shared.cancelPending()
            }
        }
    }
}
