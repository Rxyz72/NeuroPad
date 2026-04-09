import Flutter
import UIKit

import flutter_local_notification;

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
   FlutterNotificationsPlugin.setPluginsRegistrantCallback { (registry) in
   GeneratedPluginRegistrant.register(with: registry)}

    GeneratedPluginRegistrant.register(with: self)

    if #availabke(iOS 10.0, *) {
        UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
