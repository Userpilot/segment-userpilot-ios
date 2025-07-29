//
//  UserpilotManager.swift
//  UserpilotSample
//
//  Created by Motasem Hamed on 18/08/2024.
//

import Foundation
import UIKit
import SegmentUserpilot
import Segment
import Userpilot

class SegmentManager {
    
    // MARK: - Public Properties
    
    static let shared = SegmentManager()
    
    // MARK: - Private Properties
    
    /**
     We have made the Userpilot instance optional to allow flexibility in switching the token at runtime.
     However, this approach is not recommended because the token is intended to be configured only once.
     For better practice, declare the Userpilot instance inside init.
     */
    private var analytics = Analytics(configuration: Configuration(writeKey: "PLACEHOLDER_KEY")
        .trackApplicationLifecycleEvents(true))
    
    private let userpilotDestination = UserpilotDestination { config in
        config.logging(enabled: true)
    }
    
    // MARK: - Life Cycle
    
    private init() { }
    
    // MARK: - Userpilot SDK APIs
    
    func initialize() {
        analytics.add(plugin: userpilotDestination)
        userpilotDestination.userpilot?.navigationDelegate = self
    }
    
    /// Userpilot Settings
    @discardableResult
    func settings() -> [String: Any] {
        return userpilotDestination.userpilot?.settings() ?? [:]
    }
    
    /// Identify user
    func identify(userID: String, properties: [String: Any]? = nil) {
        analytics.identify(userId: userID, traits: properties)
    }
    
    func group(groupID: String, properties: [String: Any]? = nil) {
        analytics.group(groupId: groupID, traits: properties)
    }
    
    /// Logout user
    func logout() {
        analytics.reset()
    }
    
    /// Track screens
    func screen(_ screenTitle: String) {
        analytics.screen(title: screenTitle)
    }
    
    /// Track user events
    func track(eventName: String, properties: [String: Any]? = nil) {
        analytics.track(name: eventName, properties: properties)
    }
    
}

// MARK: - UserpilotNavigationDelegate

extension SegmentManager: UserpilotNavigationDelegate {

    func navigate(to url: URL) {
        delay(1) {
            if url.scheme == "userpilot-example" {
                guard let destination = url.host else {
                    return
                }
                if destination == "demo" {
                    FlowRoutingManager.shared.openViewController(DeepLinkViewController.newInstance())
                } else if destination == "identify" {
                    FlowRoutingManager.shared.openViewController(IdentifyViewController.newInstance())
                } else if destination == "screen_one" {
                    FlowRoutingManager.shared.openViewController(ScreenOneViewController.newInstance())
                } else if destination == "screen_two" {
                    FlowRoutingManager.shared.openViewController(ScreenTwoViewController.newInstance())
                }
            } else if url.scheme?.contains("http") == true || url.scheme?.contains("https") == true {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
    }

}
