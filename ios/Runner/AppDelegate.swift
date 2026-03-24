import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let restTimerLiveActivityChannelName =
    "athlos/rest_timer_live_activity"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let didFinish = super.application(
      application,
      didFinishLaunchingWithOptions: launchOptions
    )

    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: restTimerLiveActivityChannelName,
        binaryMessenger: controller.binaryMessenger
      )
      channel.setMethodCallHandler { [weak self] call, result in
        self?.handleRestTimerLiveActivity(call: call, result: result)
      }
    }

    return didFinish
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }

  private func handleRestTimerLiveActivity(
    call: FlutterMethodCall,
    result: @escaping FlutterResult
  ) {
    guard #available(iOS 16.1, *) else {
      result(false)
      return
    }

    switch call.method {
    case "upsert":
      guard
        let args = call.arguments as? [String: Any],
        let title = args["title"] as? String,
        let subtitle = args["subtitle"] as? String,
        let endAtEpochMs = args["endAtEpochMs"] as? Int64
      else {
        result(
          FlutterError(
            code: "bad_arguments",
            message: "Missing upsert arguments",
            details: nil
          )
        )
        return
      }

      let endAt = Date(timeIntervalSince1970: TimeInterval(endAtEpochMs) / 1000.0)
      Task {
        do {
          try await RestTimerLiveActivityManager.shared.upsert(
            title: title,
            subtitle: subtitle,
            endAt: endAt
          )
          result(true)
        } catch {
          result(false)
        }
      }
    case "end":
      let args = call.arguments as? [String: Any]
      let dismissImmediately = args?["dismissImmediately"] as? Bool ?? true
      Task {
        await RestTimerLiveActivityManager.shared.end(
          dismissImmediately: dismissImmediately
        )
        result(nil)
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
