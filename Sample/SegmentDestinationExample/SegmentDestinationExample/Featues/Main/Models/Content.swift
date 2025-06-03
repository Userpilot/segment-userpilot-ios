//
//  Content.swift
//  UserpilotSample
//
//  Created by Motasem Hamed on 19/08/2024.
//

import Foundation

enum Content {
    case identify
    case screens
    case events

    var title: String {
        switch self {
        case .identify:
            return "Identify"
        case .screens:
            return "Screens"
        case .events:
            return "Track events"
        }
    }
}
