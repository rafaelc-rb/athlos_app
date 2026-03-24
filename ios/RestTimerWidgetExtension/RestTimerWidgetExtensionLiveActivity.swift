//
//  RestTimerWidgetExtensionLiveActivity.swift
//  RestTimerWidgetExtension
//
//  Created by Rafael Ribeiro on 24/03/26.
//

import ActivityKit
import SwiftUI
import WidgetKit

struct RestTimerWidgetExtensionLiveActivity: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: AthlosRestTimerAttributes.self) { context in
      VStack(alignment: .leading, spacing: 6) {
        Text(context.state.title).font(.headline)
        Text(context.state.subtitle).font(.subheadline)
        Text(context.state.endAt, style: .timer)
          .font(.title2.monospacedDigit())
      }
      .padding()
    } dynamicIsland: { context in
      DynamicIsland {
        DynamicIslandExpandedRegion(.leading) {
          Text("Descanso")
        }
        DynamicIslandExpandedRegion(.trailing) {
          Text(context.state.endAt, style: .timer)
            .monospacedDigit()
        }
        DynamicIslandExpandedRegion(.bottom) {
          Text(context.state.subtitle)
        }
      } compactLeading: {
        Text("R")
      } compactTrailing: {
        Text(context.state.endAt, style: .timer)
          .monospacedDigit()
      } minimal: {
        Text(context.state.endAt, style: .timer)
          .monospacedDigit()
      }
    }
  }
}
