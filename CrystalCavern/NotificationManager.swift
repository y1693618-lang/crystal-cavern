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
//  ・許可はメニューの「お知らせの設定」を押したときにだけ尋ねます。
//
//  以前はアプリを離れたときに自動で尋ねていました。ところが全画面の広告が
//  出ると WebView は「隠れた」と判断し、そこでも尋ねてしまい、広告の上に
//  許可の確認画面が重なりました。自動で尋ねるのをやめて直しています。
//

import UIKit
import UserNotifications

final class NotificationManager: NSObject, UNUserNotificationCenterDelegate {

    static let shared = NotificationManager()
    private override init() { super.init() }

    private let identifier = "cave-full"

    // MARK: - 予約

    /// すでに許可されているときだけ予約します。ここで許可を求めることはありません。
    func scheduleCaveFull(afterSeconds seconds: Int, perSecond rate: Int, paused: Bool) {
        cancelPending()

        // 知らせる中身がないときは何もしない
        guard !paused, rate > 0, seconds > 60 else { return }

        UNUserNotificationCenter.current().getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .authorized, .provisional:
                self.add(seconds: seconds)
            default:
                break       // 未回答でも拒否でも、黙って何もしない
            }
        }
    }

    // MARK: - 許可（メニューから押されたときだけ）

    /// まだ答えていなければ許可を尋ね、すでに答えたあとなら設定アプリを開きます。
    /// どちらの場合も、押した本人が予期している動きになります。
    func promptOrOpenSettings() {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            if settings.authorizationStatus == .notDetermined {
                // 音は使わないゲームなので、音の許可は求めません。
                center.requestAuthorization(options: [.alert, .badge],
                                            completionHandler: { _, _ in })
            } else {
                DispatchQueue.main.async { Self.openAppSettings() }
            }
        }
    }

    private static func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString),
              UIApplication.shared.canOpenURL(url) else { return }
        UIApplication.shared.open(url)
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
