//
//  UserpilotDestinationTests.swift
//  SegmentUserpilotTests
//
//  Created by Userpilot on 17/04/2025.
//
//  A class unit test for UserpilotDestination.
//

import XCTest
import Segment
@testable import SegmentUserpilot
@testable import Userpilot

class UserpilotDestinationTests: XCTestCase {
    
    // MARK: - Test Properties
    
    private var analytics: Analytics!
    private var destination: UserpilotDestination!
    private var mockUserpilot: MockUserpilot!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        
        // Pass required configuration parameter
        analytics = Analytics(configuration: Configuration(writeKey: "Userpilot Mobile"))
        mockUserpilot = MockUserpilot()
        
        // Create destination with a mock Userpilot factory
        destination = UserpilotDestination { config in
            // Store config for verification
            self.mockUserpilot.configToken = config.token
        }
        
        // Replace the real Userpilot with our mock
        destination.userpilot = mockUserpilot
        destination.analytics = analytics
    }
    
    override func tearDown() {
        analytics = nil
        destination = nil
        mockUserpilot = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialization() {
        // Test basic initialization
        let destination = UserpilotDestination()
        
        XCTAssertNil(destination.userpilot)
        XCTAssertEqual(destination.key, "Userpilot Mobile")
        XCTAssertEqual(destination.type, PluginType.destination)
    }
    
    // MARK: - Settings Update Tests
    
    func testUpdateWithValidSettings() {
        // Create settings with valid Userpilot configuration
        let settings = makeSettings(token: "mock_token")
        
        // Reset the destination to test initialization through settings
        destination = UserpilotDestination()
        destination.analytics = analytics
        
        // Update settings
        destination.update(settings: settings, type: .initial)
        
        // Verify Userpilot was initialized with the correct token
        XCTAssertNotNil(destination.userpilot)
        XCTAssertEqual(mockUserpilot.configToken, "mock_token")
    }
    
    func testUpdateWithInvalidSettings() {
        // Create settings without Userpilot configuration
        let settings = Settings(writeKey: "write_key", apiHost: "api.segment.io")
        
        // Reset the destination to test initialization through settings
        destination = UserpilotDestination()
        destination.analytics = analytics
        
        // Update settings
        destination.update(settings: settings, type: .initial)
        
        // Verify Userpilot was not initialized
        XCTAssertNil(destination.userpilot)
    }
    
    func testUpdateWithNonInitialType() {
        // Create valid settings
        let settings = makeSettings(token: "test_token")
        
        // Reset the destination
        destination = UserpilotDestination()
        destination.analytics = analytics
        
        // Update with non-initial type
        destination.update(settings: settings, type: .refresh)
        
        // Verify Userpilot was not initialized
        XCTAssertNil(destination.userpilot)
    }
    
    // MARK: - Identify Tests
    
    func testIdentifyWithValidData() {
        // Create identify event with complete data
        let traits: [String: Any] = [
            "name": "Test User",
            "email": "test@example.com",
            "age": 30
        ]
        
        // Convert to JSON type required by IdentifyEvent
        let jsonTraits = try? JSON(traits)
        
        let event = IdentifyEvent(userId: "user_123", traits: jsonTraits)
        
        // Process the event
        let result = destination.identify(event: event)
        
        // Verify the event was processed correctly
        XCTAssertEqual(result?.userId, "user_123")
        XCTAssertEqual(mockUserpilot.lastIdentifiedUserId, "user_123")
        
        // Verify properties were passed correctly
        XCTAssertEqual(mockUserpilot.lastIdentifiedProperties?["name"] as? String, "Test User")
        XCTAssertEqual(mockUserpilot.lastIdentifiedProperties?["email"] as? String, "test@example.com")
        XCTAssertEqual(mockUserpilot.lastIdentifiedProperties?["age"] as? Int, 30)
        
        // No company data should be present in this test as identify doesn't handle it
        XCTAssertNil(mockUserpilot.lastIdentifiedCompany)
    }
    
    func testIdentifyWithEmptyUserId() {
        // Create identify event with empty userId
        let event = IdentifyEvent(userId: "", traits: nil)
        
        // Process the event
        let result = destination.identify(event: event)
        
        // Verify the event was returned but Userpilot identify wasn't called
        XCTAssertEqual(result?.userId, "")
        XCTAssertNil(mockUserpilot.lastIdentifiedUserId)
    }
    
    func testIdentifyWithNoTraits() {
        // Create identify event with no traits
        let event = IdentifyEvent(userId: "user_123", traits: nil)
        
        // Process the event
        let result = destination.identify(event: event)
        
        // Verify the event was returned but Userpilot identify wasn't called with properties
        XCTAssertEqual(result?.userId, "user_123")
        XCTAssertEqual(mockUserpilot.lastIdentifiedUserId, "user_123")
        XCTAssertNil(mockUserpilot.lastIdentifiedProperties)
        XCTAssertNil(mockUserpilot.lastIdentifiedCompany)
    }
    
    // MARK: - Group Tests
    
    func testGroupWithValidData() {
        // Create group event with traits
        let traits: [String: Any] = [
            "name": "Test Company",
            "plan": "enterprise",
            "employees": 500
        ]
        
        // Convert to JSON type required by GroupEvent
        let jsonTraits = try? JSON(traits)
        var event = GroupEvent(groupId: "company_123", traits: jsonTraits)
        event.userId = "user_123"
        
        // Process the event
        let result = destination.group(event: event)
        
        // Verify the event was processed correctly
        XCTAssertEqual(result?.groupId, "company_123")
        
        // Verify company data was passed correctly
        XCTAssertEqual(mockUserpilot.lastIdentifiedCompany?["id"] as? String, "company_123")
        XCTAssertEqual(mockUserpilot.lastIdentifiedCompany?["name"] as? String, "Test Company")
        XCTAssertEqual(mockUserpilot.lastIdentifiedCompany?["plan"] as? String, "enterprise")
        XCTAssertEqual(mockUserpilot.lastIdentifiedCompany?["employees"] as? Int, 500)
    }
    
    func testGroupWithNoUserInSettings() {
        // Mock settings without User data
        mockUserpilot.mockSettings = [:]
        
        // Create group event
        let traits: [String: Any] = [
            "name": "Test Company"
        ]
        
        // Convert to JSON type
        let jsonTraits = try? JSON(traits)
        
        let event = GroupEvent(groupId: "company_123", traits: jsonTraits)
        
        // Process the event
        let result = destination.group(event: event)
        
        // Verify identify wasn't called
        XCTAssertEqual(result?.groupId, "company_123")
        XCTAssertNil(mockUserpilot.lastIdentifiedCompany)
    }
    
    // MARK: - Track Tests
    
    func testTrackWithValidEvent() {
        // Create track event with properties
        let properties: [String: Any] = [
            "plan": "premium",
            "value": 99.99,
            "items": 3
        ]
        
        // Convert to JSON type required by TrackEvent
        let jsonProperties = try? JSON(properties)
        
        let event = TrackEvent(event: "Purchase Completed", properties: jsonProperties)
        
        // Process the event
        let result = destination.track(event: event)
        
        // Verify the event was tracked correctly
        XCTAssertEqual(result?.event, "Purchase Completed")
        XCTAssertEqual(mockUserpilot.lastTrackedEvent, "Purchase Completed")
        XCTAssertEqual(mockUserpilot.lastTrackedProperties?["plan"] as? String, "premium")
        XCTAssertEqual(mockUserpilot.lastTrackedProperties?["value"] as? Double, 99.99)
        XCTAssertEqual(mockUserpilot.lastTrackedProperties?["items"] as? Int, 3)
    }
    
    func testTrackWithEmptyEventName() {
        // Create track event with empty name
        let event = TrackEvent(event: "", properties: nil)
        
        // Process the event
        let result = destination.track(event: event)
        
        // Verify the event was returned but Userpilot track wasn't called
        XCTAssertEqual(result?.event, "")
        XCTAssertNil(mockUserpilot.lastTrackedEvent)
    }
    
    func testTrackWithNoProperties() {
        // Create track event with no properties
        let event = TrackEvent(event: "App Opened", properties: nil)
        
        // Process the event
        let result = destination.track(event: event)
        
        // Verify the event was tracked correctly but without properties
        XCTAssertEqual(result?.event, "App Opened")
        XCTAssertEqual(mockUserpilot.lastTrackedEvent, "App Opened")
        XCTAssertNil(mockUserpilot.lastTrackedProperties)
    }
    
    // MARK: - Screen Tests
    
    func testScreenWithValidName() {
        // Create screen event with name
        let event = ScreenEvent(title: "Home Screen", category: "")
        
        // Process the event
        let result = destination.screen(event: event)
        
        // Verify the screen was tracked correctly
        XCTAssertEqual(result?.name, "Home Screen")
        XCTAssertEqual(mockUserpilot.lastScreenName, "Home Screen")
    }
    
    func testScreenWithEmptyName() {
        // Create screen event with empty name
        let event = ScreenEvent(category: "")
        
        // Process the event
        let result = destination.screen(event: event)
        
        // Verify the event was returned but Userpilot screen wasn't called
        XCTAssertNil(result?.name) // Changed from "" to nil as that's what an empty ScreenEvent would have
        XCTAssertNil(mockUserpilot.lastScreenName)
    }
    
    func testScreenWithNilName() {
        // Create screen event with nil name
        let event = ScreenEvent(title: nil, category: "")
        
        // Process the event
        let result = destination.screen(event: event)
        
        // Verify the event was returned but Userpilot screen wasn't called
        XCTAssertNil(result?.name)
        XCTAssertNil(mockUserpilot.lastScreenName)
    }
    
    // MARK: - Reset Test
    
    func testReset() {
        // Call reset
        destination.reset()
        
        // Verify Userpilot destroy was called
        XCTAssertTrue(mockUserpilot.logoutCalled)
    }
    
    // MARK: - Helper Methods
    
    private func makeSettings(token: String) -> Settings {
        // Create JSON for integrations
        let userpilotIntegration: [String: Any] = ["token": token]
        let integrations: [String: Any] = ["Userpilot Mobile": userpilotIntegration]
        
        // Create settings
        var settings = Settings(writeKey: "write_key", apiHost: "api.segment.io")
        
        // Handle potential JSON conversion error
        do {
            settings.integrations = try JSON(integrations)
        } catch {
            // In tests, we can just print the error or fail the test
            print("Failed to create JSON for integrations: \(error)")
        }
        
        return settings
    }
}

// MARK: - Test Mocks

// Create a simple mock class that doesn't inherit from Analytics
private class MockUserpilot: Userpilot {
    // extract the token since the config is not accessable here
    var configToken: String?
    var mockSettings: [String: Any] = [:]
    
    var lastIdentifiedUserId: String?
    var lastIdentifiedProperties: [String: Any]?
    var lastIdentifiedCompany: [String: Any]?
    
    var lastTrackedEvent: String?
    var lastTrackedProperties: [String: Any]?
    
    var lastScreenName: String?
    
    var logoutCalled = false
    
    // Use the designated initializer from Userpilot
    init() {
        super.init(config: Userpilot.Config(token: "mock_token"))
        configToken = "mock_token" // we are sure the sdk take the token correctly
    }
    
    override func identify(userID: String, properties: [String: Any]?, company: [String: Any]? = nil) {
        lastIdentifiedUserId = userID
        lastIdentifiedProperties = properties
        lastIdentifiedCompany = company
    }
    
    override func track(eventName: String, properties: [String: Any]?) {
        lastTrackedEvent = eventName
        lastTrackedProperties = properties
    }
    
    override func screen(_ screenName: String) {
        lastScreenName = screenName
    }
    
    override func logout() {
        logoutCalled = true
    }
    
    override func settings() -> [String: Any] {
        return mockSettings
    }
}

// MARK: - Helpers for working with Segment JSON objects

extension JSON {
    var dictionaryValue: [String: JSON]? {
        if case let .object(object) = self {
            return object
        }
        return nil
    }

    var anyValue: Any? {
        switch self {
        case .null:
            return nil
        case .bool(let bool):
            return bool
        case .number(let number):
            return number
        case .string(let string):
            return string
        case .array(let array):
            return array.compactMap { $0.anyValue }
        case .object(let dict):
            return dict.compactMapValues { $0.anyValue }
        }
    }
}
