import Foundation
import ActivityKit

@available(iOS 16.1, *)
struct AthlosRestTimerAttributes: ActivityAttributes {
  public struct ContentState: Codable, Hashable {
    var title: String
    var subtitle: String
    var endAt: Date
  }

  var id: String
}

@available(iOS 16.1, *)
final class RestTimerLiveActivityManager {
  static let shared = RestTimerLiveActivityManager()

  private var currentActivity: Activity<AthlosRestTimerAttributes>?

  private init() {}

  func upsert(title: String, subtitle: String, endAt: Date) async throws {
    let state = AthlosRestTimerAttributes.ContentState(
      title: title,
      subtitle: subtitle,
      endAt: endAt
    )

    if let activity = currentActivity {
      if #available(iOS 16.2, *) {
        let content = ActivityContent(state: state, staleDate: endAt)
        await activity.update(content)
      } else {
        await activity.update(using: state)
      }
      return
    }

    let attributes = AthlosRestTimerAttributes(id: UUID().uuidString)
    if #available(iOS 16.2, *) {
      let content = ActivityContent(state: state, staleDate: endAt)
      currentActivity = try Activity.request(
        attributes: attributes,
        content: content,
        pushType: nil
      )
    } else {
      currentActivity = try Activity.request(
        attributes: attributes,
        contentState: state,
        pushType: nil
      )
    }
  }

  func end(dismissImmediately: Bool) async {
    guard let activity = currentActivity else { return }
    if #available(iOS 16.2, *) {
      let policy: ActivityUIDismissalPolicy =
        dismissImmediately ? .immediate : .default
      await activity.end(nil, dismissalPolicy: policy)
    } else {
      await activity.end(nil, dismissalPolicy: .immediate)
    }
    currentActivity = nil
  }
}
