//
//  ConsentManager.swift
//
//  EU・イギリスの人に広告を出すとき、Google の規約では「同意の確認画面」を
//  出すことが必須です。その画面は AdMob の管理画面で作り、ここから呼び出します。
//
//  ──────────────────────────────────────────────────────────────
//  ⚠ このファイルだけは、ビルドが通らない可能性が少し高めです。
//
//    UserMessagingPlatform は、バージョン3で Swift 側の名前が変わりました。
//    手元で試せないので、新しいほうの名前で書いてあります。
//
//    もしエラーが出たら、次のどちらかをしてください。
//
//    (A) README の「名前の対応表」を見て、古い名前に直す
//    (B) このファイルを消して、CrystalCavernApp.swift の
//        「await ConsentManager.shared.gather()」の1行も消す
//
//    (B) でもアプリは動きます。ただし EU 向けに配信するまでに
//    戻す必要があります。まず1回ビルドを通したいときは (B) が早いです。
//  ──────────────────────────────────────────────────────────────
//

import UIKit

#if canImport(UserMessagingPlatform)
import UserMessagingPlatform
#endif

/// 状態をふたつ覚えておくだけの入れ物です。
/// ・resumed … 待っている処理を再開したか（二度目を防ぐ。二度 resume すると落ちます）
/// ・replied … Google から返事が来たか
private final class ConsentGate {
    var resumed = false
    var replied = false
}

@MainActor
final class ConsentManager {

    static let shared = ConsentManager()
    private init() { }

    /// 同意が必要な地域の人にだけ、確認画面を出します。
    /// 日本から遊んでいる人には何も起きません。
    func gather() async {
        #if canImport(UserMessagingPlatform)
        await withCheckedContinuation { (done: CheckedContinuation<Void, Never>) in

            let gate = ConsentGate()
            let resumeOnce = {
                guard !gate.resumed else { return }
                gate.resumed = true
                done.resume()
            }

            // 通信が詰まると Google からの返事が来ないことがあります。
            // その場合ここで止まったままになり、追跡の確認も広告の読み込みも
            // 二度と始まりません。8秒待って返事が無ければ先へ進みます。
            //
            // 「返事が来たかどうか」で判断しているので、EU の人が同意画面を
            // 読んでいる最中に割り込むことはありません。
            DispatchQueue.main.asyncAfter(deadline: .now() + 8) {
                if !gate.replied { resumeOnce() }
            }

            let parameters = RequestParameters()

            ConsentInformation.shared.requestConsentInfoUpdate(with: parameters) { error in
                Task { @MainActor in
                    gate.replied = true
                    // 取得に失敗しても、そこで止めません。
                    // 同意が要らない地域と同じ扱いにして先へ進みます。
                    guard error == nil,
                          let root = AdsManager.topViewController() else {
                        resumeOnce(); return
                    }
                    ConsentForm.loadAndPresentIfRequired(from: root) { _ in
                        resumeOnce()
                    }
                }
            }
        }
        #endif
    }
}
