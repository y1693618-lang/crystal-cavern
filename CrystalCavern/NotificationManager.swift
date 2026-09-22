//
//  NotificationManager.swift
//
//  留守のあいだに貯まる分は最大8時間で頭打ちになります。
//  そこを過ぎると、それ以上は増えません。
//  8時間経ったところで一度だけ知らせ、取りこぼしを防ぎます。
//
//  ・通知は「一度だけ」「8時間後」。それ以上は送りません。
//  ・毎秒の収入がない人には送りません（知らせる中身がないため）。
//  ・一時停止中の人にも送りません。
//  ・許可は初回の離脱時にだけ尋ね、断られたら二度と尋ねません。
//

import UIKit
import UserNotifications

final class NotificationManager: NSObject, UNUserNotificationCenterDelegate {

    static let shared = NotificationManager()
    private override init() { super.init() }

    private let identifier = "cave-full"
    private let askedKey = "cc-asked-notify"

    // MARK: - 予約

    func scheduleCaveFull(afterSeconds seconds: Int, perSecond rate: Int, paused: Bool) {
        cancelPending()

        // 知らせる価値がないときは、そもそも許可も求めない
        guard !paused, rate > 0, seconds > 60 else { return }

        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            switch settings.authorizationStatus {

            case .notDetermined:
                // 初回だけ尋ねる。断られたらそれきり。
                guard !UserDefaults.standard.bool(forKey: self.askedKey) else { return }
                UserDefaults.standard.set(true, forKey: self.askedKey)
                center.requestAuthorization(options: [.alert, .badge]) { granted, _ in
                    if granted { self.add(seconds: seconds) }
                }

            case .authorized, .provisional:
                self.add(seconds: seconds)

            default:
                break
            }
        }
    }

    private func add(seconds: Int) {
        let ja = Locale.preferredLanguages.first?.hasPrefix("ja") ?? false

        let content = UNMutableNotificationContent()
        content.title = ja ? "洞窟がいっぱいです" : "The cave is full"
        content.body = ja
            ? "留守のあいだに貯まる分が上限に達しました。受け取りに来てください。"
            : "What accumulates while you are away has reached its limit. Come and collect it."
        // 音は鳴らしません。このゲームは最初から音を使わない作りです。
        content.sound = nil

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: TimeInterval(seconds), repeats: false)

        let request = UNNotificationRequest(
            identifier: identifier, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }

    func cancelPending() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    // MARK: - 前面にいるときの扱い

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        // アプリを開いている最中に出す必要はない
        return []
    }
}
