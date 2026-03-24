import ActivityKit
import Foundation

@available(iOS 16.1, *)
final class RestTimerLiveActivityManager {
  static let shared = RestTimerLiveActivityManager()

  private var currentActivity: Activity<AthlosRestTimerAttributes>?

  private init() {}

  func upsert(title: String, subtitle: String, endAt: Date) async throws {
    let newState = AthlosRestTimerAttributes.ContentState(
      title: title,
      subtitle: subtitle,
      endAt: endAt
    )

    if let activity = activeActivity() {
      await activity.update(using: newState)
      return
    }

    let attributes = AthlosRestTimerAttributes(id: UUID().uuidString)
    currentActivity = try Activity.request(
      attributes: attributes,
      contentState: newState,
      pushType: nil
    )
  }

  func end(dismissImmediately: Bool) async {
    guard let activity = activeActivity() else { return }

    let dismissalPolicy: ActivityUIDismissalPolicy =
      dismissImmediately ? .immediate : .default
    await activity.end(dismissalPolicy: dismissalPolicy)
    currentActivity = nil
  }

  private func activeActivity() -> Activity<AthlosRestTimerAttributes>? {
    if let currentActivity, currentActivity.activityState != .dismissed {
      return currentActivity
    }

    currentActivity = Activity<AthlosRestTimerAttributes>.activities.first
    return currentActivity
  }
}
