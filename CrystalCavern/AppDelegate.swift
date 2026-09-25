//
//  AppDelegate.swift
//
//  起動時に一度だけ必要な初期化をまとめています。
//
//  広告の SDK（AdMob）の初期化は、ここではしません。
//  追跡許可の返事が出てから AdsManager が始めます。
//  Apple は「追跡に使えるデータを集める前に尋ねること」を求めているためです。
//

import UIKit
import UserNotifications

final class AppDelegate: NSObject, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {

        // 通知のタップを受け取れるようにしておく
        UNUserNotificationCenter.current().delegate = NotificationManager.shared

        return true
    }
}
