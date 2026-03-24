import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let restTimerLiveActivityChannelName =
    "athlos/rest_timer_live_activity"
  private var restTimerLiveActivityChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let didFinish = super.application(
      application,
      didFinishLaunchingWithOptions: launchOptions
    )

    if let controller = window?.rootViewController as? FlutterViewController {
      setupRestTimerLiveActivityChannel(binaryMessenger: controller.binaryMessenger)
    }

    return didFinish
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    guard
      let registrar = engineBridge.pluginRegistry.registrar(
        forPlugin: "RestTimerLiveActivityChannel"
      )
    else {
      return
    }
    setupRestTimerLiveActivityChannel(binaryMessenger: registrar.messenger())
  }

  private func setupRestTimerLiveActivityChannel(
    binaryMessenger: FlutterBinaryMessenger
  ) {
    if restTimerLiveActivityChannel != nil {
      return
    }
    let channel = FlutterMethodChannel(
      name: restTimerLiveActivityChannelName,
      binaryMessenger: binaryMessenger
    )
    channel.setMethodCallHandler { [weak self] call, result in
      self?.handleRestTimerLiveActivity(call: call, result: result)
    }
    restTimerLiveActivityChannel = channel
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
        let subtitle = args["subtitle"] as? String
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

      let endAtEpochMs: Int64?
      if let value = args["endAtEpochMs"] as? Int64 {
        endAtEpochMs = value
      } else if let value = args["endAtEpochMs"] as? Int {
        endAtEpochMs = Int64(value)
      } else if let value = args["endAtEpochMs"] as? NSNumber {
        endAtEpochMs = value.int64Value
      } else if let value = args["endAtEpochMs"] as? Double {
        endAtEpochMs = Int64(value)
      } else {
        endAtEpochMs = nil
      }

      guard let endAtEpochMs else {
        result(
          FlutterError(
            code: "bad_arguments",
            message: "Invalid endAtEpochMs argument",
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
