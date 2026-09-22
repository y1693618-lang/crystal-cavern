//
//  GameScreen.swift
//
//  WKWebView をひとつ置いて、同梱した game.html を表示するだけの画面です。
//  ネットからページを読み込むことはありません。機内モードでも動きます。
//

import SwiftUI
import WebKit

struct GameScreen: UIViewRepresentable {

    func makeCoordinator() -> GameBridge { GameBridge() }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()

        // ゲームからアプリを呼ぶための窓口。名前はゲーム側の Native と揃える。
        let content = WKUserContentController()
        content.add(context.coordinator, name: "ccHaptic")  // 触覚
        content.add(context.coordinator, name: "ccAds")     // リワード広告
        content.add(context.coordinator, name: "ccIdle")    // 通知の予約
        config.userContentController = content

        // 動画広告を全画面で出すので、勝手に再生されないようにはしない
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isOpaque = false
        webView.backgroundColor = UIColor(red: 0.043, green: 0.047, blue: 0.059, alpha: 1) // #0B0C0F
        webView.scrollView.backgroundColor = webView.backgroundColor
        webView.scrollView.bounces = false                 // 画面が上下に跳ねないように
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.navigationDelegate = context.coordinator

        #if DEBUG
        // Mac の Safari からこの WebView を調べられるようにする（開発中のみ）
        if #available(iOS 16.4, *) { webView.isInspectable = true }
        #endif

        context.coordinator.webView = webView

        // 同梱ファイルを読み込む。www フォルダごと Bundle に入れておくこと。
        if let url = Bundle.main.url(forResource: "game", withExtension: "html", subdirectory: "www") {
            webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        } else {
            assertionFailure("www/game.html が Bundle に入っていません。"
                             + "Xcode で www フォルダを『Create folder references』で追加してください。")
        }

        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) { }
}
