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
                    // 同意の確認 → 追跡許可 → 広告の開始。中身は AdsManager に。
                    Task { await AdsManager.shared.prepareIfNeeded() }
                }
        }
        // 引数がひとつの書き方です。iOS 17 で新しい形に変わりましたが、
        // このアプリは iOS 16 から動かすので、こちらを使います。
        // （iOS 17 以降では「古い書き方です」という警告が出ますが、動きます）
        .onChange(of: scenePhase) { phase in
            if phase == .active {
                // 前面に戻ってきたら、予約していた通知は役目を終えている
                NotificationManager.shared.cancelPending()
                // 起動時に追跡許可の画面が出られなかった場合の、やり直し
                Task { await AdsManager.shared.prepareIfNeeded() }
            }
        }
    }
}
