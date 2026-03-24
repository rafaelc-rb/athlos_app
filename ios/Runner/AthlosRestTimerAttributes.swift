//
//  AthlosRestTimerAttributes.swift
//  Runner
//
//  Created by Rafael Ribeiro on 24/03/26.
//

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
