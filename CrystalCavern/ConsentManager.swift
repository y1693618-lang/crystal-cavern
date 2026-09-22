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

@MainActor
final class ConsentManager {

    static let shared = ConsentManager()
    private init() { }

    /// 同意が必要な地域の人にだけ、確認画面を出します。
    /// 日本から遊んでいる人には何も起きません。
    func gather() async {
        #if canImport(UserMessagingPlatform)
        await withCheckedContinuation { (done: CheckedContinuation<Void, Never>) in

            let parameters = RequestParameters()

            ConsentInformation.shared.requestConsentInfoUpdate(with: parameters) { error in
                Task { @MainActor in
                    // 取得に失敗しても、そこで止めません。
                    // 同意が要らない地域と同じ扱いにして先へ進みます。
                    guard error == nil,
                          let root = AdsManager.topViewController() else {
                        done.resume(); return
                    }
                    ConsentForm.loadAndPresentIfRequired(from: root) { _ in
                        done.resume()
                    }
                }
            }
        }
        #endif
    }
}
