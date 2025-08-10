//
//  UserpilotDestination.swift
//  SegmentUserpilot
//
//  Created by Userpilot on 16/Apr/2025.
//
//  An implementation of the Userpilot destination for Segment's mobile SDK.
//  Integrates Userpilot with Segment's device mode tracking.
//
//

import Foundation
import Segment
import Userpilot

/// Internal settings container for decoding Userpilot-related config from Segment settings.
private struct UserpilotSettings: Codable {
    let token: String
}

/// A Segment destination plugin that integrates with the Userpilot mobile SDK.
public class UserpilotDestination: DestinationPlugin {
    
    // MARK: - Plugin Properties
    
    public let timeline = Timeline()
    public let key = "Userpilot Mobile"
    public let type = PluginType.destination
    public weak var analytics: Analytics?
    
    /// The Userpilot SDK instance managed by this plugin.
    public internal(set) var userpilot: Userpilot?
    
    /// Configuration closure passed on init to customize Userpilot.Config.
    private var config: ((Userpilot.Config) -> Void)?
    
    // MARK: - Initialization
    
    /// Initializes the plugin with optional configuration customization.
    /// - Parameter configuration: A closure that allows additional setup on `Userpilot.Config`.
    public init(config: ((Userpilot.Config) -> Void)? = nil) {
        self.config = config
    }
    
    // MARK: - DestinationPlugin Lifecycle
    
    public func update(settings: Settings, type: UpdateType) {
        guard type == .initial else { return }
        
        // Extract Userpilot-specific settings
        guard let userpilotSettings: UserpilotSettings = settings.integrationSettings(forPlugin: self) else {
            analytics?.log(message: "\(key) destination is disabled via settings")
            return
        }
        
        // Apply additional config customizations if provided
        let config = Userpilot.Config(token: userpilotSettings.token)
            .apply(config)
        
        // Initialize Userpilot SDK
        userpilot = Userpilot(config: config)
        analytics?.log(message: "\(key) destination loaded")
    }
    
    public func identify(event: IdentifyEvent) -> IdentifyEvent? {
        guard let userpilot = userpilot,
              let userId = event.userId ?? event.anonymousId,
              !userId.isEmpty
        else { return event }
        
        userpilot.identify(
            userId: userId,
            properties: event.traits?.mapSanitizeToUserpilotProperties
        )
        
        return event
    }
    
    public func group(event: GroupEvent) -> GroupEvent? {
        guard let userpilot = userpilot,
              let userId = event.userId ?? event.anonymousId,
              !userId.isEmpty
        else { return event }
        
        let properties = event.traits?.mapSanitizeToUserpilotProperties ?? [:]
        var company: [String: Any] = ["id": event.groupId ?? ""]
        company.merge(properties) { (_, new) in new }
        
        userpilot.identify(
            userId: userId,
            company: company
        )
        
        return event
    }
    
    public func track(event: TrackEvent) -> TrackEvent? {
        if let userpilot = userpilot, event.isValid {
            userpilot.track(eventName: event.event, properties: event.properties?.mapToUserpilotProperties)
        }
        return event
    }
    
    public func screen(event: ScreenEvent) -> ScreenEvent? {
        if let userpilot = userpilot, let title = event.title {
            userpilot.screen(title)
        }
        return event
    }
    
    public func reset() {
        userpilot?.logout()
    }
}

// MARK: - Private Helpers

private extension TrackEvent {
    /// Determines whether a track event is valid (i.e., has a non-empty event name).
    var isValid: Bool {
        !event.isEmpty
    }
}

private extension ScreenEvent {
    /// Returns the screen name if it is valid (i.e., non-empty).
    var title: String? {
        guard let title = name, !title.isEmpty else { return nil }
        return title
    }
}

private extension Userpilot.Config {
    /// Applies an optional configuration closure and returns the result.
    func apply(_ config: ((Userpilot.Config) -> Void)?) -> Self {
        config?(self)
        return self
    }
}

private extension JSON {
    /// Converts Segment JSON properties to a dictionary supported by Userpilot.
    /// Filters out unsupported types.
    var mapToUserpilotProperties: [String: Any]? {
        guard let properties = dictionaryValue else { return nil }

        var filteredProperties: [String: Any] = [:]

        for (key, value) in properties {
            filteredProperties[key] = value
        }

        return filteredProperties.isEmpty ? nil : filteredProperties
    }
    
    var mapSanitizeToUserpilotProperties: [String: Any]? {
        guard let properties = dictionaryValue else { return nil }

        var filteredProperties: [String: Any] = [:]

        for (key, value) in properties {
            let mappedKey = (key == "createdAt") ? "created_at" : key
            filteredProperties[mappedKey] = value
        }

        return filteredProperties.isEmpty ? nil : filteredProperties
    }
    
}

/// Validates if a value is of a type supported by Userpilot traits.
private func isAllowedPropertyType(_ value: Any) -> Bool {
    switch value {
    case is String, is Bool, is NSNumber, is Int, is Float, is Double:
        return true
    default:
        return false
    }
}
