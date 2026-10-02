//
//  ConsentManager.swift
//
//  EU・イギリス・スイスの人に広告を出すとき、Google の規約では「同意の確認画面」を
//  出すことが必須です。その画面は AdMob の管理画面（プライバシーとメッセージ →
//  欧州の規制）で作ってあり、ここから呼び出します。
//
//  日本など対象外の地域の人には、何も表示されません。
//
//  1.1 で変えたこと
//  ・部品（UserMessagingPlatform）を project.yml で名前を書いて入れるようにし、
//    「見つかったときだけ動く」という書き方をやめました。
//    見つからなければ黙って飛ばす作りだったので、本当に入っているかを
//    誰も確かめられなかったためです。いまは入っていなければビルドが止まります。
//  ・同意をあとから変えるための入口（プライバシー設定）を足しました。
//    必要な地域の人にだけ、ゲームのメニューにボタンが出ます。
//

import UIKit
import UserMessagingPlatform

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
                    // 前回までに分かっている状態のまま先へ進みます。
                    guard error == nil,
                          let root = AdsManager.topViewController() else {
                        resumeOnce(); return
                    }
                    ConsentForm.loadAndPresentIfRequired(from: root) { _ in
                        Task { @MainActor in
                            GameBridge.current?.sendPrivacyStatus()
                            resumeOnce()
                        }
                    }
                }
            }
        }
    }

    /// 広告を読み込んでよい状態か。
    /// 日本など対象外の地域では、返事が来ていれば true です。
    /// EU などで、まだ同意画面に答えていない間は false になります。
    var canRequestAds: Bool {
        ConsentInformation.shared.canRequestAds
    }

    /// 同意をあとから変える入口を見せる必要がある人か。
    /// EU・イギリス・スイスの人で true になります。日本の人は false です。
    var privacyOptionsRequired: Bool {
        ConsentInformation.shared.privacyOptionsRequirementStatus == .required
    }

    /// 同意の内容を変える画面を出します（ゲームのメニューから呼ばれます）。
    func presentPrivacyOptions() {
        guard let root = AdsManager.topViewController() else { return }
        ConsentForm.presentPrivacyOptionsForm(from: root) { _ in
            // 変えた結果、広告を読み込めるようになった場合に備える
            Task { @MainActor in AdsManager.shared.preload() }
        }
    }
}
