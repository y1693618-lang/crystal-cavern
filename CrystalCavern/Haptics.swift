//
//  Haptics.swift
//
//  このゲームは音をいっさい使いません。
//  iPhone では、音の代わりに触覚を返せます。ウェブ版にはない、
//  この端末でしか出せない手応えです。
//
//  端末の設定で「システムの触覚」を切っている人には何も起きません。
//  それでよく、触覚がなくても画面だけで遊べる作りのままです。
//

import UIKit

final class Haptics {

    static let shared = Haptics()
    private init() { }

    // 生成に少し時間がかかるので、使い回して即応させる
    private let light = UIImpactFeedbackGenerator(style: .light)
    private let medium = UIImpactFeedbackGenerator(style: .medium)
    private let heavy = UIImpactFeedbackGenerator(style: .heavy)
    private let notice = UINotificationFeedbackGenerator()

    /// 連打で振動しっぱなしにならないよう、最短の間隔を決めておく
    private var lastTap = Date.distantPast
    private let minimumTapGap: TimeInterval = 0.04

    func play(_ kind: String) {
        DispatchQueue.main.async { self.run(kind) }
    }

    private func run(_ kind: String) {
        switch kind {

        case "tap":
            // 採掘。いちばん回数が多いので、いちばん軽く。
            let now = Date()
            guard now.timeIntervalSince(lastTap) >= minimumTapGap else { return }
            lastTap = now
            light.impactOccurred(intensity: 0.7)
            light.prepare()

        case "buy":
            // 設備の購入。手応えをひとつ上げる。
            medium.impactOccurred()
            medium.prepare()

        case "orb":
            // 光る球を拾った。うれしい出来事なので成功の合図。
            notice.notificationOccurred(.success)
            notice.prepare()

        case "seam":
            // 新しい鉱脈。節目なので重く。
            heavy.impactOccurred()
            heavy.prepare()

        case "rebirth":
            // 再結晶。いちばん大きな節目。
            notice.notificationOccurred(.success)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                self.heavy.impactOccurred()
                self.heavy.prepare()
            }

        default:
            break
        }
    }

    /// 画面が出たところで温めておくと、最初のひと押しから遅れない
    func warmUp() {
        light.prepare()
        medium.prepare()
        heavy.prepare()
        notice.prepare()
    }
}
