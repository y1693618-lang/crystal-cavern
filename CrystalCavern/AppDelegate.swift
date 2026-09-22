//
//  AppDelegate.swift
//
//  起動時に一度だけ必要な初期化をまとめています。
//

import UIKit
import UserNotifications
import GoogleMobileAds

final class AppDelegate: NSObject, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {

        // AdMob の初期化。追跡許可の返事を待つ必要はなく、
        // 許可がなくても広告は出ます（単価が下がるだけ）。
        MobileAds.shared.start(completionHandler: nil)

        // 通知のタップを受け取れるようにしておく
        UNUserNotificationCenter.current().delegate = NotificationManager.shared

        return true
    }
}
