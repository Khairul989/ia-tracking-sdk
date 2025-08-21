import Flutter
import UIKit
import os.log
import StoreKit
import AdSupport
import AppTrackingTransparency

/**
 * Flutter plugin for IA Tracking iOS SDK with enhanced features
 *
 * This plugin provides comprehensive Flutter bindings for iOS user action tracking
 * with enterprise-grade features including:
 * - SKAdNetwork integration for attribution
 * - Revenue and In-App Purchase tracking
 * - Global properties management
 * - Privacy compliance (GDPR, COPPA, ATT)
 * - Push notification handling
 * - Automatic data flushing
 */
@available(iOS 12.0, *)
public class IaTrackingPlugin: NSObject, FlutterPlugin {
    
    private static let logger = OSLog(subsystem: "com.iav3.iatracking", category: "IaTrackingPlugin")
    private let channelName = "ia_tracking"
    private let flushInterval: TimeInterval = 5.0 // 5 seconds
    
    // Default API configuration (can be overridden)
    private let defaultApiBaseUrl = "https://enormous-right-mule.ngrok-free.app"
    private let apiVersion = "v1"
    private let trackingEndpoint = "track"
    
    // Core tracking state
    private var isInitialized = false
    private var isEnabled = true
    private var currentUserId: String?
    private var currentSessionId: String = UUID().uuidString
    private var apiUrl: String?
    private var apiKey: String?
    
    // Enhanced features state
    private var trackingEnabled = true
    private var dataSharingEnabled = true
    private var allTrackingStopped = false
    private var currentDeviceId: String?
    private var sessionTimeoutMinutes = 30
    private var deviceToken: String?
    private var globalProperties: [String: String] = [:]
    
    // SDK info
    private var wrapperName: String?
    private var wrapperVersion: String?
    private let sdkVersion = "1.1.0"
    
    // Action storage and flushing
    private var userActions: [UserAction] = []
    private var flushTimer: Timer?
    private let actionQueue = DispatchQueue(label: "com.iav3.iatracking.actions", qos: .background)
    
    // SKAdNetwork state
    private var skanEnabled = true
    private var conversionValue: Int = 0
    
    // IDFA and ATT (App Tracking Transparency) state
    private var cachedIDFA: String?
    private var cachedATTStatus: Any? // Will hold ATTrackingManager.AuthorizationStatus on iOS 14+
    private var idfaCollectionAttempted = false
    
    // Data structure for user actions
    struct UserAction {
        let id: String
        let actionType: String
        let screenName: String?
        let elementId: String?
        let elementType: String?
        let userId: String?
        let sessionId: String
        let timestamp: Int64
        let properties: [String: Any]
        let deviceInfo: [String: Any]
        let appVersion: String?
        let sdkVersion: String
        var isSynced: Bool = false
        var retryCount: Int = 0
        
        init(id: String, actionType: String, screenName: String?, elementId: String?, elementType: String?, 
             userId: String?, sessionId: String, timestamp: Int64, properties: [String: Any], 
             deviceInfo: [String: Any], appVersion: String?, sdkVersion: String) {
            self.id = id
            self.actionType = actionType
            self.screenName = screenName
            self.elementId = elementId
            self.elementType = elementType
            self.userId = userId
            self.sessionId = sessionId
            self.timestamp = timestamp
            self.properties = properties
            self.deviceInfo = deviceInfo
            self.appVersion = appVersion
            self.sdkVersion = sdkVersion
        }
    }
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "ia_tracking", binaryMessenger: registrar.messenger())
        let instance = IaTrackingPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        
        os_log("Plugin registered", log: logger, type: .info)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        os_log("Method called: %@", log: Self.logger, type: .debug, call.method)
        
        switch call.method {
        // Core tracking methods
        case "initialize":
            initialize(call: call, result: result)
        case "trackScreenView":
            trackScreenView(call: call, result: result)
        case "trackButtonTap":
            trackButtonTap(call: call, result: result)
        case "trackTextInput":
            trackTextInput(call: call, result: result)
        case "trackNavigation":
            trackNavigation(call: call, result: result)
        case "trackSearch":
            trackSearch(call: call, result: result)
        case "trackCustomEvent":
            trackCustomEvent(call: call, result: result)
        case "startNewSession":
            startNewSession(result: result)
        case "setUserId":
            setUserId(call: call, result: result)
        case "setEnabled":
            setEnabled(call: call, result: result)
        case "isEnabled":
            isEnabled(result: result)
        case "getActionStatistics":
            getActionStatistics(result: result)
        case "getUnsyncedActions":
            getUnsyncedActions(call: call, result: result)
        case "markActionsAsSynced":
            markActionsAsSynced(call: call, result: result)
        case "getCleanupStats":
            getCleanupStats(result: result)
        case "performCleanup":
            performCleanup(result: result)
        case "deleteAllUserData":
            deleteAllUserData(result: result)
        case "flush":
            flush(result: result)
            
        // Enhanced features
        case "initializeEnhanced":
            initializeEnhanced(call: call, result: result)
        case "trackRevenue":
            trackRevenue(call: call, result: result)
        case "trackIOSInAppPurchase":
            trackIOSInAppPurchase(call: call, result: result)
        case "trackAndroidInAppPurchase":
            trackAndroidInAppPurchase(call: call, result: result)
        case "setGlobalProperty":
            setGlobalProperty(call: call, result: result)
        case "unsetGlobalProperty":
            unsetGlobalProperty(call: call, result: result)
        case "getGlobalProperties":
            getGlobalProperties(result: result)
        case "clearGlobalProperties":
            clearGlobalProperties(result: result)
        case "setTrackingEnabled":
            setTrackingEnabled(call: call, result: result)
        case "isTrackingEnabled":
            isTrackingEnabled(result: result)
        case "setDataSharingEnabled":
            setDataSharingEnabled(call: call, result: result)
        case "isDataSharingEnabled":
            isDataSharingEnabled(result: result)
        case "trackingOptIn":
            trackingOptIn(result: result)
        case "trackingOptOut":
            trackingOptOut(result: result)
        case "stopAllTracking":
            stopAllTracking(result: result)
        case "resumeAllTracking":
            resumeAllTracking(result: result)
        case "isAllTrackingStopped":
            isAllTrackingStopped(result: result)
        case "setDeviceId":
            setDeviceId(call: call, result: result)
        case "unsetDeviceId":
            unsetDeviceId(result: result)
        case "setSessionTimeout":
            setSessionTimeout(call: call, result: result)
            
        // SKAdNetwork methods (iOS specific)
        case "skanRegisterAppForAttribution":
            skanRegisterAppForAttribution(result: result)
        case "skanUpdateConversionValue":
            skanUpdateConversionValue(call: call, result: result)
        case "skanUpdateConversionValues":
            skanUpdateConversionValues(call: call, result: result)
        case "skanGetConversionValue":
            skanGetConversionValue(result: result)
            
        // Push notifications and uninstall tracking
        case "registerDeviceTokenForUninstall":
            registerDeviceTokenForUninstall(call: call, result: result)
        case "setFCMDeviceToken":
            setFCMDeviceToken(call: call, result: result)
        case "handlePushNotification":
            handlePushNotification(call: call, result: result)
            
        // Advanced configuration
        case "setWrapperInfo":
            setWrapperInfo(call: call, result: result)
        case "getSdkVersion":
            getSdkVersion(result: result)
            
        // iOS App Tracking Transparency (ATT) methods
        case "requestTrackingPermission":
            requestTrackingPermission(result: result)
        case "getTrackingAuthorizationStatus":
            getTrackingAuthorizationStatus(result: result)
        case "isTrackingAuthorized":
            isTrackingAuthorized(result: result)
        case "getIDFA":
            getIDFA(result: result)
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    // MARK: - Helper Methods
    
    private func generateActionId() -> String {
        return UUID().uuidString
    }
    
    private func generateSessionId() -> String {
        return UUID().uuidString
    }
    
    private func generateBatchId() -> String {
        return UUID().uuidString
    }
    
    private func createDeviceInfo() -> [String: Any] {
        var deviceInfo: [String: Any] = [
            "platform": "iOS",
            "osVersion": UIDevice.current.systemVersion,
            "appVersion": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0",
            "deviceModel": UIDevice.current.model,
            "locale": Locale.current.identifier,
            "timezone": TimeZone.current.identifier,
            "carrier": getCarrierName(),
            "connection": getConnectionType(),
            "manufacturer": "Apple"
        ]
        
        // Add cached IDFA if collection has been attempted
        if idfaCollectionAttempted {
            deviceInfo["idfa"] = cachedIDFA
            if #available(iOS 14.0, *) {
                deviceInfo["attStatus"] = attStatusToString(cachedATTStatus)
            } else {
                deviceInfo["attStatus"] = cachedIDFA != nil ? "authorized" : "denied"
            }
            
            if cachedIDFA != nil {
                os_log("Using cached IDFA in device info", log: Self.logger, type: .debug)
            } else {
                os_log("IDFA not available - using nil", log: Self.logger, type: .debug)
            }
        } else {
            // IDFA collection not yet attempted or completed
            deviceInfo["idfa"] = nil
            deviceInfo["attStatus"] = "notDetermined"
            os_log("IDFA not yet collected - using nil", log: Self.logger, type: .debug)
        }
        
        return deviceInfo
    }
    
    private func getCarrierName() -> String {
        // iOS carrier info requires additional frameworks and permissions
        return "Unknown"
    }
    
    private func getConnectionType() -> String {
        // Basic connection type detection
        return "unknown"
    }
    
    private func attStatusToString(_ status: Any?) -> String {
        if #available(iOS 14.5, *) {
            guard let attStatus = status as? ATTrackingManager.AuthorizationStatus else { return "unknown" }
            
            switch attStatus {
            case .authorized:
                return "authorized"
            case .denied:
                return "denied"
            case .restricted:
                return "restricted"
            case .notDetermined:
                return "notDetermined"
            @unknown default:
                return "unknown"
            }
        } else {
            // For iOS < 14.5, return simplified status based on LAT setting
            if #available(iOS 14.0, *), let attStatus = status as? ATTrackingManager.AuthorizationStatus {
                return attStatus == .authorized ? "authorized" : "denied"
            }
            return "unknown"
        }
    }
    
    private func resolveApiUrl(configServerUrl: String?) -> String? {
        // 1. Check environment variable first (highest priority)
        if let envApiUrl = ProcessInfo.processInfo.environment["IA_TRACKING_API_URL"], !envApiUrl.isEmpty {
            os_log("Using API URL from environment variable", log: Self.logger, type: .info)
            return envApiUrl
        }
        
        // 2. Check if provided URL is base64 encoded
        if let configServerUrl = configServerUrl, !configServerUrl.isEmpty {
            if configServerUrl.hasPrefix("aHR0c") { // Base64 encoded HTTPS URLs typically start with this
                if let data = Data(base64Encoded: configServerUrl),
                   let decoded = String(data: data, encoding: .utf8) {
                    os_log("Using decoded base64 API URL", log: Self.logger, type: .info)
                    return decoded
                } else {
                    os_log("Failed to decode base64 URL, using as-is", log: Self.logger, type: .error)
                    return configServerUrl
                }
            } else {
                return configServerUrl
            }
        }
        
        return nil
    }
    
    /**
     * Collect IDFA asynchronously on background thread (called once during initialization)
     */
    private func collectIDFAAsync() {
        if idfaCollectionAttempted { return }
        
        idfaCollectionAttempted = true
        os_log("Starting IDFA collection", log: Self.logger, type: .info)
        
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }
            
            // Check iOS version compatibility
            if #available(iOS 14.5, *) {
                // iOS 14.5+ with App Tracking Transparency
                let currentStatus = ATTrackingManager.trackingAuthorizationStatus
                self.cachedATTStatus = currentStatus
                
                switch currentStatus {
                case .authorized:
                    // User has granted permission, collect IDFA
                    let idfa = ASIdentifierManager.shared().advertisingIdentifier.uuidString
                    self.cachedIDFA = idfa == "00000000-0000-0000-0000-000000000000" ? nil : idfa
                    os_log("IDFA collected successfully with ATT authorization: %@", log: Self.logger, type: .info, self.cachedIDFA ?? "nil")
                    
                case .denied, .restricted:
                    // User denied or restricted, cannot collect IDFA
                    self.cachedIDFA = nil
                    os_log("IDFA collection denied/restricted by ATT status: %@", log: Self.logger, type: .info, String(describing: currentStatus))
                    
                case .notDetermined:
                    // User hasn't been asked yet, IDFA not available without permission
                    self.cachedIDFA = nil
                    os_log("ATT permission not determined, IDFA not collected", log: Self.logger, type: .info)
                    
                @unknown default:
                    // Future ATT status values
                    self.cachedIDFA = nil
                    os_log("Unknown ATT status, IDFA not collected", log: Self.logger, type: .error)
                }
            } else {
                // iOS < 14.5, no ATT required
                let idfa = ASIdentifierManager.shared().advertisingIdentifier.uuidString
                let isLimitAdTrackingEnabled = ASIdentifierManager.shared().isAdvertisingTrackingEnabled
                
                if isLimitAdTrackingEnabled {
                    self.cachedIDFA = idfa == "00000000-0000-0000-0000-000000000000" ? nil : idfa
                    os_log("IDFA collected successfully on iOS <14.5: %@", log: Self.logger, type: .info, self.cachedIDFA ?? "nil")
                } else {
                    self.cachedIDFA = nil
                    os_log("IDFA collection disabled by LAT setting on iOS <14.5", log: Self.logger, type: .info)
                }
                
                // Set a compatible ATT status for older iOS versions
                if #available(iOS 14.0, *) {
                    self.cachedATTStatus = isLimitAdTrackingEnabled ? ATTrackingManager.AuthorizationStatus.authorized : ATTrackingManager.AuthorizationStatus.denied
                }
            }
        }
    }
    
    private func startAutoFlush() {
        stopAutoFlush()
        
        flushTimer = Timer.scheduledTimer(withTimeInterval: flushInterval, repeats: true) { [weak self] _ in
            self?.flushUnsyncedActions()
        }
        
        os_log("Auto-flush started with %.1f second interval", log: Self.logger, type: .info, flushInterval)
    }
    
    private func stopAutoFlush() {
        flushTimer?.invalidate()
        flushTimer = nil
        os_log("Auto-flush stopped", log: Self.logger, type: .info)
    }
    
    private func flushUnsyncedActions() {
        actionQueue.async { [weak self] in
            guard let self = self else { return }
            
            // Skip if no API URL configured
            guard let apiUrl = self.apiUrl, !apiUrl.isEmpty else {
                os_log("No API URL configured, skipping auto-flush", log: Self.logger, type: .debug)
                return
            }
            
            let unsyncedActions = self.userActions.filter { !$0.isSynced && $0.retryCount < 3 }
            
            guard !unsyncedActions.isEmpty else {
                os_log("No unsynced actions to flush", log: Self.logger, type: .debug)
                return
            }
            
            os_log("Flushing %d unsynced actions to API", log: Self.logger, type: .info, unsyncedActions.count)
            
            self.sendActionsToApi(actions: unsyncedActions) { success in
                DispatchQueue.main.async {
                    if success {
                        // Mark actions as synced
                        for i in 0..<self.userActions.count {
                            if let actionId = unsyncedActions.first(where: { $0.id == self.userActions[i].id })?.id {
                                self.userActions[i].isSynced = true
                            }
                        }
                        os_log("Successfully synced %d actions", log: Self.logger, type: .info, unsyncedActions.count)
                    } else {
                        // Increment retry count for failed actions
                        for i in 0..<self.userActions.count {
                            if let _ = unsyncedActions.first(where: { $0.id == self.userActions[i].id }) {
                                self.userActions[i].retryCount += 1
                            }
                        }
                        os_log("Failed to sync actions, retry count incremented", log: Self.logger, type: .error)
                    }
                }
            }
        }
    }
    
    private func sendActionsToApi(actions: [UserAction], completion: @escaping (Bool) -> Void) {
        guard let apiUrl = apiUrl, let url = URL(string: apiUrl) else {
            os_log("Invalid API URL", log: Self.logger, type: .error)
            completion(false)
            return
        }
        
        do {
            // Convert actions to API format
            let events = actions.map { action -> [String: Any] in
                var event: [String: Any] = [
                    "id": action.id,
                    "actionType": action.actionType,
                    "timestamp": action.timestamp,
                    "userId": action.userId ?? NSNull(),
                    "sessionId": action.sessionId,
                    "appVersion": action.appVersion ?? "1.0.0",
                    "sdkVersion": action.sdkVersion
                ]
                
                // Add optional fields if present
                if let screenName = action.screenName {
                    event["screenName"] = screenName
                }
                if let elementId = action.elementId {
                    event["elementId"] = elementId
                }
                if let elementType = action.elementType {
                    event["elementType"] = elementType
                }
                
                // Merge properties with global properties
                var allProperties = action.properties
                for (key, value) in globalProperties {
                    allProperties[key] = value
                }
                if !allProperties.isEmpty {
                    event["properties"] = allProperties
                }
                
                // Add device info
                event["deviceInfo"] = action.deviceInfo
                
                // Add global properties as separate field
                if !globalProperties.isEmpty {
                    event["globalProperties"] = globalProperties
                }
                
                return event
            }
            
            // Create batch info
            let batchId = generateBatchId()
            let batchInfo: [String: Any] = [
                "batchId": batchId,
                "eventCount": events.count,
                "flushReason": "auto_flush",
                "flushTimestamp": Int64(Date().timeIntervalSince1970 * 1000)
            ]
            
            // Create session info
            let sessionInfo: [String: Any] = [
                "sessionId": currentSessionId,
                "sessionStart": Int64(Date().timeIntervalSince1970 * 1000),
                "userId": currentUserId ?? NSNull()
            ]
            
            // Create complete payload according to API documentation
            let payload: [String: Any] = [
                "events": events,
                "batchInfo": batchInfo,
                "deviceInfo": createDeviceInfo(),
                "sessionInfo": sessionInfo
            ]
            
            let jsonData = try JSONSerialization.data(withJSONObject: payload)
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("IA-Tracking-SDK/1.1.0 (Platform: iOS)", forHTTPHeaderField: "User-Agent")
            request.httpBody = jsonData
            
            // Add API key header if configured
            if let apiKey = apiKey {
                request.setValue(apiKey, forHTTPHeaderField: "X-API-Key")
            }
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    os_log("Network error during API request: %@", log: Self.logger, type: .error, error.localizedDescription)
                    completion(false)
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 {
                        if let responseData = data, let responseString = String(data: responseData, encoding: .utf8) {
                            os_log("API request successful: %d", log: Self.logger, type: .info, httpResponse.statusCode)
                            os_log("Response: %@", log: Self.logger, type: .debug, responseString)
                        }
                        completion(true)
                    } else {
                        if let responseData = data, let errorString = String(data: responseData, encoding: .utf8) {
                            os_log("API request failed: %d - %@", log: Self.logger, type: .error, httpResponse.statusCode, errorString)
                        } else {
                            os_log("API request failed: %d", log: Self.logger, type: .error, httpResponse.statusCode)
                        }
                        completion(false)
                    }
                } else {
                    completion(false)
                }
            }.resume()
            
        } catch {
            os_log("Error serializing actions: %@", log: Self.logger, type: .error, error.localizedDescription)
            completion(false)
        }
    }
    
    private func actionToDict(_ action: UserAction) -> [String: Any] {
        return [
            "id": action.id,
            "actionType": action.actionType,
            "screenName": action.screenName ?? NSNull(),
            "elementId": action.elementId ?? NSNull(),
            "elementType": action.elementType ?? NSNull(),
            "userId": action.userId ?? NSNull(),
            "sessionId": action.sessionId,
            "timestamp": action.timestamp,
            "properties": action.properties,
            "deviceInfo": action.deviceInfo,
            "appVersion": action.appVersion ?? NSNull(),
            "sdkVersion": action.sdkVersion,
            "isSynced": action.isSynced,
            "retryCount": action.retryCount
        ]
    }
    
    // MARK: - Core Implementation Methods
    
    private func initialize(call: FlutterMethodCall, result: @escaping FlutterResult) {
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else {
                DispatchQueue.main.async { result(FlutterError(code: "INITIALIZATION_ERROR", message: "Plugin deallocated", details: nil)) }
                return
            }
            
            guard let arguments = call.arguments as? [String: Any] else {
                DispatchQueue.main.async { result(FlutterError(code: "INITIALIZATION_ERROR", message: "Invalid arguments", details: nil)) }
                return
            }
            
            os_log("Initializing SDK", log: Self.logger, type: .info)
            
            // Extract configuration
            self.currentUserId = arguments["userId"] as? String
            self.apiKey = arguments["apiKey"] as? String
            let configServerUrl = arguments["serverUrl"] as? String
            
            // Resolve API URL
            self.apiUrl = self.resolveApiUrl(configServerUrl: configServerUrl) ?? "\\(self.defaultApiBaseUrl)/\\(self.apiVersion)/\\(self.trackingEndpoint)"
            
            // Start new session
            self.currentSessionId = self.generateSessionId()
            
            // Mark as initialized
            self.isInitialized = true
            
            // Start IDFA collection as soon as we're initialized
            self.collectIDFAAsync()
            
            // Start auto-flush timer
            DispatchQueue.main.async {
                self.startAutoFlush()
            }
            
            DispatchQueue.main.async {
                result(nil)
                os_log("Initialization successful", log: Self.logger, type: .info)
            }
        }
    }
    
    private func trackScreenView(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard isEnabled && isInitialized && !allTrackingStopped else {
            result(nil)
            return
        }
        
        guard let arguments = call.arguments as? [String: Any],
              let screenName = arguments["screenName"] as? String else {
            result(FlutterError(code: "INVALID_ARGUMENT", message: "screenName is required", details: nil))
            return
        }
        
        actionQueue.async { [weak self] in
            guard let self = self else { return }
            
            os_log("Tracking screen view: %@", log: Self.logger, type: .debug, screenName)
            
            var properties: [String: Any] = [
                "screen_name": screenName
            ]
            properties.merge(self.globalProperties) { (_, new) in new }
            
            let action = UserAction(
                id: self.generateActionId(),
                actionType: "screen_view",
                screenName: screenName,
                elementId: nil,
                elementType: nil,
                userId: self.currentUserId,
                sessionId: self.currentSessionId,
                timestamp: Int64(Date().timeIntervalSince1970 * 1000),
                properties: properties,
                deviceInfo: self.createDeviceInfo(),
                appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
                sdkVersion: self.sdkVersion
            )
            
            self.userActions.append(action)
            
            DispatchQueue.main.async {
                os_log("Screen view tracked and stored locally: %@", log: Self.logger, type: .debug, action.id)
                result(nil)
            }
        }
    }
    
    private func trackButtonTap(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard isEnabled && isInitialized && !allTrackingStopped else {
            result(nil)
            return
        }
        
        guard let arguments = call.arguments as? [String: Any],
              let elementId = arguments["elementId"] as? String,
              let screenName = arguments["screenName"] as? String else {
            result(FlutterError(code: "INVALID_ARGUMENT", message: "elementId and screenName are required", details: nil))
            return
        }
        
        actionQueue.async { [weak self] in
            guard let self = self else { return }
            
            os_log("Tracking button tap: %@ on %@", log: Self.logger, type: .debug, elementId, screenName)
            
            var properties: [String: Any] = [
                "element_id": elementId,
                "element_type": "button"
            ]
            
            if let coordinatesX = arguments["coordinatesX"] as? Double,
               let coordinatesY = arguments["coordinatesY"] as? Double {
                properties["tap_x"] = coordinatesX
                properties["tap_y"] = coordinatesY
            }
            
            properties.merge(self.globalProperties) { (_, new) in new }
            
            let action = UserAction(
                id: self.generateActionId(),
                actionType: "button_tap",
                screenName: screenName,
                elementId: elementId,
                elementType: "button",
                userId: self.currentUserId,
                sessionId: self.currentSessionId,
                timestamp: Int64(Date().timeIntervalSince1970 * 1000),
                properties: properties,
                deviceInfo: self.createDeviceInfo(),
                appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
                sdkVersion: self.sdkVersion
            )
            
            self.userActions.append(action)
            
            DispatchQueue.main.async {
                os_log("Button tap tracked and stored locally: %@", log: Self.logger, type: .debug, action.id)
                result(nil)
            }
        }
    }
    
    private func trackTextInput(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard isEnabled && isInitialized && !allTrackingStopped else {
            result(nil)
            return
        }
        
        guard let arguments = call.arguments as? [String: Any],
              let elementId = arguments["elementId"] as? String,
              let screenName = arguments["screenName"] as? String else {
            result(FlutterError(code: "INVALID_ARGUMENT", message: "elementId and screenName are required", details: nil))
            return
        }
        
        actionQueue.async { [weak self] in
            guard let self = self else { return }
            
            os_log("Tracking text input: %@ on %@", log: Self.logger, type: .debug, elementId, screenName)
            
            var properties: [String: Any] = [
                "element_id": elementId,
                "element_type": "input"
            ]
            
            if let inputLength = arguments["inputLength"] as? Int {
                properties["input_length"] = inputLength
            }
            
            properties.merge(self.globalProperties) { (_, new) in new }
            
            let action = UserAction(
                id: self.generateActionId(),
                actionType: "text_input",
                screenName: screenName,
                elementId: elementId,
                elementType: "input",
                userId: self.currentUserId,
                sessionId: self.currentSessionId,
                timestamp: Int64(Date().timeIntervalSince1970 * 1000),
                properties: properties,
                deviceInfo: self.createDeviceInfo(),
                appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
                sdkVersion: self.sdkVersion
            )
            
            self.userActions.append(action)
            
            DispatchQueue.main.async {
                os_log("Text input tracked and stored locally: %@", log: Self.logger, type: .debug, action.id)
                result(nil)
            }
        }
    }
    
    private func trackNavigation(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard isEnabled && isInitialized && !allTrackingStopped else {
            result(nil)
            return
        }
        
        guard let arguments = call.arguments as? [String: Any],
              let fromScreen = arguments["fromScreen"] as? String,
              let toScreen = arguments["toScreen"] as? String else {
            result(FlutterError(code: "INVALID_ARGUMENT", message: "fromScreen and toScreen are required", details: nil))
            return
        }
        
        actionQueue.async { [weak self] in
            guard let self = self else { return }
            
            os_log("Tracking navigation: %@ -> %@", log: Self.logger, type: .debug, fromScreen, toScreen)
            
            var properties: [String: Any] = [
                "event_name": "navigation",
                "action_subtype": "navigation",
                "from_screen": fromScreen,
                "to_screen": toScreen
            ]
            
            if let method = arguments["method"] as? String {
                properties["navigation_method"] = method
            }
            
            properties.merge(self.globalProperties) { (_, new) in new }
            
            let action = UserAction(
                id: self.generateActionId(),
                actionType: "custom",
                screenName: toScreen,
                elementId: nil,
                elementType: nil,
                userId: self.currentUserId,
                sessionId: self.currentSessionId,
                timestamp: Int64(Date().timeIntervalSince1970 * 1000),
                properties: properties,
                deviceInfo: self.createDeviceInfo(),
                appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
                sdkVersion: self.sdkVersion
            )
            
            self.userActions.append(action)
            
            DispatchQueue.main.async {
                os_log("Navigation tracked and stored locally: %@", log: Self.logger, type: .debug, action.id)
                result(nil)
            }
        }
    }
    
    private func trackSearch(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard isEnabled && isInitialized && !allTrackingStopped else {
            result(nil)
            return
        }
        
        guard let arguments = call.arguments as? [String: Any],
              let query = arguments["query"] as? String,
              let screenName = arguments["screenName"] as? String else {
            result(FlutterError(code: "INVALID_ARGUMENT", message: "query and screenName are required", details: nil))
            return
        }
        
        actionQueue.async { [weak self] in
            guard let self = self else { return }
            
            os_log("Tracking search: '%@' on %@", log: Self.logger, type: .debug, query, screenName)
            
            var properties: [String: Any] = [
                "event_name": "search",
                "action_subtype": "search",
                "search_query": query
            ]
            
            if let resultsCount = arguments["resultsCount"] as? Int {
                properties["results_count"] = resultsCount
            }
            
            properties.merge(self.globalProperties) { (_, new) in new }
            
            let action = UserAction(
                id: self.generateActionId(),
                actionType: "custom",
                screenName: screenName,
                elementId: nil,
                elementType: "search",
                userId: self.currentUserId,
                sessionId: self.currentSessionId,
                timestamp: Int64(Date().timeIntervalSince1970 * 1000),
                properties: properties,
                deviceInfo: self.createDeviceInfo(),
                appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
                sdkVersion: self.sdkVersion
            )
            
            self.userActions.append(action)
            
            DispatchQueue.main.async {
                os_log("Search tracked and stored locally: %@", log: Self.logger, type: .debug, action.id)
                result(nil)
            }
        }
    }
    
    private func trackCustomEvent(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard isEnabled && isInitialized && !allTrackingStopped else {
            result(nil)
            return
        }
        
        guard let arguments = call.arguments as? [String: Any],
              let eventName = arguments["eventName"] as? String,
              let screenName = arguments["screenName"] as? String else {
            result(FlutterError(code: "INVALID_ARGUMENT", message: "eventName and screenName are required", details: nil))
            return
        }
        
        actionQueue.async { [weak self] in
            guard let self = self else { return }
            
            os_log("Tracking custom event: '%@' on %@", log: Self.logger, type: .debug, eventName, screenName)
            
            var properties: [String: Any] = [
                "event_name": eventName,
                "action_subtype": "custom_event"
            ]
            
            if let elementId = arguments["elementId"] as? String {
                properties["element_id"] = elementId
            }
            
            if let customProperties = arguments["properties"] as? [String: Any] {
                properties.merge(customProperties) { (_, new) in new }
            }
            
            properties.merge(self.globalProperties) { (_, new) in new }
            
            let action = UserAction(
                id: self.generateActionId(),
                actionType: "custom",
                screenName: screenName,
                elementId: arguments["elementId"] as? String,
                elementType: "custom",
                userId: self.currentUserId,
                sessionId: self.currentSessionId,
                timestamp: Int64(Date().timeIntervalSince1970 * 1000),
                properties: properties,
                deviceInfo: self.createDeviceInfo(),
                appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
                sdkVersion: self.sdkVersion
            )
            
            self.userActions.append(action)
            
            DispatchQueue.main.async {
                os_log("Custom event tracked and stored locally: %@", log: Self.logger, type: .debug, action.id)
                result(nil)
            }
        }
    }
    
    private func startNewSession(result: @escaping FlutterResult) {
        actionQueue.async { [weak self] in
            guard let self = self else { return }
            
            os_log("Starting new session", log: Self.logger, type: .debug)
            
            self.currentSessionId = self.generateSessionId()
            
            DispatchQueue.main.async {
                result(nil)
            }
        }
    }
    
    private func setUserId(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let arguments = call.arguments as? [String: Any] else {
            result(FlutterError(code: "INVALID_ARGUMENT", message: "Invalid arguments", details: nil))
            return
        }
        
        actionQueue.async { [weak self] in
            guard let self = self else { return }
            
            self.currentUserId = arguments["userId"] as? String
            os_log("Set user ID: %@", log: Self.logger, type: .debug, self.currentUserId ?? "nil")
            
            DispatchQueue.main.async {
                result(nil)
            }
        }
    }
    
    private func setEnabled(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let arguments = call.arguments as? [String: Any],
              let enabled = arguments["enabled"] as? Bool else {
            result(FlutterError(code: "INVALID_ARGUMENT", message: "enabled parameter is required", details: nil))
            return
        }
        
        isEnabled = enabled
        os_log("Set enabled: %@", log: Self.logger, type: .debug, enabled ? "true" : "false")
        
        result(nil)
    }
    
    private func isEnabled(result: @escaping FlutterResult) {
        os_log("Is enabled: %@", log: Self.logger, type: .debug, isEnabled ? "true" : "false")
        result(isEnabled)
    }
    
    private func getActionStatistics(result: @escaping FlutterResult) {
        actionQueue.async { [weak self] in
            guard let self = self else {
                DispatchQueue.main.async {
                    result(FlutterError(code: "TRACKER_ERROR", message: "Tracker not initialized", details: nil))
                }
                return
            }
            
            let totalActions = self.userActions.count
            let syncedActions = self.userActions.filter { $0.isSynced }.count
            let unsyncedActions = self.userActions.filter { !$0.isSynced }.count
            let failedActions = self.userActions.filter { $0.retryCount >= 3 }.count
            
            let stats: [String: Any] = [
                "totalActions": totalActions,
                "syncedActions": syncedActions,
                "unsyncedActions": unsyncedActions,
                "failedActions": failedActions
            ]
            
            os_log("Action statistics: %@", log: Self.logger, type: .debug, String(describing: stats))
            
            DispatchQueue.main.async {
                result(stats)
            }
        }
    }
    
    private func getUnsyncedActions(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let arguments = call.arguments as? [String: Any] else {
            result(FlutterError(code: "INVALID_ARGUMENT", message: "Invalid arguments", details: nil))
            return
        }
        
        let limit = arguments["limit"] as? Int ?? 50
        
        actionQueue.async { [weak self] in
            guard let self = self else { return }
            
            os_log("Get unsynced actions (limit: %d)", log: Self.logger, type: .debug, limit)
            
            let unsyncedActions = Array(self.userActions
                .filter { !$0.isSynced }
                .suffix(limit))
                .map { self.actionToDict($0) }
            
            DispatchQueue.main.async {
                result(unsyncedActions)
            }
        }
    }
    
    private func markActionsAsSynced(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let arguments = call.arguments as? [String: Any],
              let actionIds = arguments["actionIds"] as? [String] else {
            result(FlutterError(code: "INVALID_ARGUMENT", message: "actionIds is required", details: nil))
            return
        }
        
        actionQueue.async { [weak self] in
            guard let self = self else { return }
            
            os_log("Mark actions as synced: %d actions", log: Self.logger, type: .debug, actionIds.count)
            
            for i in 0..<self.userActions.count {
                if actionIds.contains(self.userActions[i].id) {
                    self.userActions[i].isSynced = true
                }
            }
            
            DispatchQueue.main.async {
                result(true)
            }
        }
    }
    
    private func getCleanupStats(result: @escaping FlutterResult) {
        actionQueue.async { [weak self] in
            guard let self = self else {
                DispatchQueue.main.async {
                    result(FlutterError(code: "TRACKER_ERROR", message: "Tracker not initialized", details: nil))
                }
                return
            }
            
            let totalActions = self.userActions.count
            let syncedActions = self.userActions.filter { $0.isSynced }.count
            let unsyncedActions = self.userActions.filter { !$0.isSynced }.count
            
            let stats: [String: Any] = [
                "totalActions": totalActions,
                "syncedActions": syncedActions,
                "unsyncedActions": unsyncedActions,
                "estimatedSizeBytes": totalActions * 1024,
                "maxSizeBytes": 50 * 1024 * 1024,
                "retentionDays": 30
            ]
            
            os_log("Cleanup statistics: %@", log: Self.logger, type: .debug, String(describing: stats))
            
            DispatchQueue.main.async {
                result(stats)
            }
        }
    }
    
    private func performCleanup(result: @escaping FlutterResult) {
        actionQueue.async { [weak self] in
            guard let self = self else { return }
            
            os_log("Performing cleanup", log: Self.logger, type: .debug)
            
            // Remove old synced actions (keep last 1000)
            let syncedActions = self.userActions.filter { $0.isSynced }
            if syncedActions.count > 1000 {
                self.userActions.removeAll { action in
                    syncedActions.prefix(syncedActions.count - 1000).contains { $0.id == action.id }
                }
            }
            
            DispatchQueue.main.async {
                result(true)
            }
        }
    }
    
    private func deleteAllUserData(result: @escaping FlutterResult) {
        actionQueue.async { [weak self] in
            guard let self = self else { return }
            
            os_log("Deleting all user data", log: Self.logger, type: .debug)
            
            self.userActions.removeAll()
            self.globalProperties.removeAll()
            self.currentUserId = nil
            self.currentDeviceId = nil
            
            DispatchQueue.main.async {
                result(true)
            }
        }
    }
    
    private func flush(result: @escaping FlutterResult) {
        actionQueue.async { [weak self] in
            guard let self = self else { return }
            
            os_log("Flushing operations", log: Self.logger, type: .debug)
            
            // Manually trigger flush
            self.flushUnsyncedActions()
            
            DispatchQueue.main.async {
                result(nil)
            }
        }
    }
    
    // MARK: - Enhanced Features Implementation
    
    private func initializeEnhanced(call: FlutterMethodCall, result: @escaping FlutterResult) {
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else {
                DispatchQueue.main.async { result(FlutterError(code: "INITIALIZATION_ERROR", message: "Plugin deallocated", details: nil)) }
                return
            }
            
            guard let arguments = call.arguments as? [String: Any] else {
                DispatchQueue.main.async { result(FlutterError(code: "INITIALIZATION_ERROR", message: "Invalid arguments", details: nil)) }
                return
            }
            
            os_log("Initializing enhanced SDK", log: Self.logger, type: .info)
            
            // Extract enhanced configuration
            self.currentUserId = arguments["userId"] as? String
            self.apiKey = arguments["apiKey"] as? String
            self.currentDeviceId = arguments["deviceId"] as? String
            self.sessionTimeoutMinutes = arguments["sessionTimeoutMinutes"] as? Int ?? 30
            let configServerUrl = arguments["serverUrl"] as? String
            
            // Resolve API URL
            self.apiUrl = self.resolveApiUrl(configServerUrl: configServerUrl) ?? "\\(self.defaultApiBaseUrl)/\\(self.apiVersion)/\\(self.trackingEndpoint)"
            
            // Extract privacy settings
            if let privacy = arguments["privacy"] as? [String: Any] {
                self.trackingEnabled = privacy["trackingEnabled"] as? Bool ?? true
                self.dataSharingEnabled = privacy["dataSharingEnabled"] as? Bool ?? true
            }
            
            // Extract SKAdNetwork settings
            if let skanSettings = arguments["skanSettings"] as? [String: Any] {
                self.skanEnabled = skanSettings["enabled"] as? Bool ?? true
            }
            
            // Extract global properties
            if let globalProps = arguments["globalProperties"] as? [[String: Any]] {
                for prop in globalProps {
                    if let key = prop["key"] as? String, let value = prop["value"] as? String {
                        self.globalProperties[key] = value
                    }
                }
            }
            
            // Start new session
            self.currentSessionId = self.generateSessionId()
            self.isInitialized = true
            
            // Start auto-flush timer
            DispatchQueue.main.async {
                self.startAutoFlush()
            }
            
            DispatchQueue.main.async {
                result(nil)
                os_log("Enhanced initialization successful", log: Self.logger, type: .info)
            }
        }
    }
    
    private func trackRevenue(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard isEnabled && isInitialized && !allTrackingStopped else {
            result(nil)
            return
        }
        
        guard let arguments = call.arguments as? [String: Any] else {
            result(FlutterError(code: "INVALID_ARGUMENT", message: "Invalid arguments", details: nil))
            return
        }
        
        actionQueue.async { [weak self] in
            guard let self = self else { return }
            
            let eventName = arguments["eventName"] as? String ?? "revenue"
            let amount = arguments["amount"] as? Double ?? 0.0
            let currency = arguments["currency"] as? String ?? "USD"
            let customProperties = arguments["properties"] as? [String: Any] ?? [:]
            
            os_log("Tracking revenue: %.2f %@", log: Self.logger, type: .debug, amount, currency)
            
            var properties: [String: Any] = [
                "is_revenue_event": true,
                "r": amount,
                "pcc": currency
            ]
            properties.merge(customProperties) { (_, new) in new }
            properties.merge(self.globalProperties) { (_, new) in new }
            
            let action = UserAction(
                id: self.generateActionId(),
                actionType: "revenue",
                screenName: nil,
                elementId: nil,
                elementType: "revenue",
                userId: self.currentUserId,
                sessionId: self.currentSessionId,
                timestamp: Int64(Date().timeIntervalSince1970 * 1000),
                properties: properties,
                deviceInfo: self.createDeviceInfo(),
                appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
                sdkVersion: self.sdkVersion
            )
            
            self.userActions.append(action)
            
            DispatchQueue.main.async {
                os_log("Revenue tracked and stored locally: %@", log: Self.logger, type: .debug, action.id)
                result(nil)
            }
        }
    }
    
    private func trackIOSInAppPurchase(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard isEnabled && isInitialized && !allTrackingStopped else {
            result(nil)
            return
        }
        
        guard let arguments = call.arguments as? [String: Any] else {
            result(FlutterError(code: "INVALID_ARGUMENT", message: "Invalid arguments", details: nil))
            return
        }
        
        actionQueue.async { [weak self] in
            guard let self = self else { return }
            
            let eventName = arguments["eventName"] as? String ?? "ios_iap"
            let amount = arguments["amount"] as? Double ?? 0.0
            let currency = arguments["currency"] as? String ?? "USD"
            let productId = arguments["productId"] as? String
            let transactionId = arguments["transactionId"] as? String
            let receiptData = arguments["receiptData"] as? String
            let customProperties = arguments["properties"] as? [String: Any] ?? [:]
            
            os_log("Tracking iOS IAP: %@ - %.2f %@", log: Self.logger, type: .debug, productId ?? "unknown", amount, currency)
            
            var properties: [String: Any] = [
                "is_revenue_event": true,
                "r": amount,
                "pcc": currency,
                "platform": "ios",
                "pk": productId ?? "",
                "pti": transactionId ?? "",
                "ptr": receiptData ?? ""
            ]
            properties.merge(customProperties) { (_, new) in new }
            properties.merge(self.globalProperties) { (_, new) in new }
            
            let action = UserAction(
                id: self.generateActionId(),
                actionType: "ios_iap",
                screenName: nil,
                elementId: productId,
                elementType: "iap",
                userId: self.currentUserId,
                sessionId: self.currentSessionId,
                timestamp: Int64(Date().timeIntervalSince1970 * 1000),
                properties: properties,
                deviceInfo: self.createDeviceInfo(),
                appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
                sdkVersion: self.sdkVersion
            )
            
            self.userActions.append(action)
            
            DispatchQueue.main.async {
                os_log("iOS IAP tracked and stored locally: %@", log: Self.logger, type: .debug, action.id)
                result(nil)
            }
        }
    }
    
    private func trackAndroidInAppPurchase(call: FlutterMethodCall, result: @escaping FlutterResult) {
        // iOS implementation - will log but not process Android-specific data
        os_log("Android IAP tracking called on iOS - ignoring", log: Self.logger, type: .debug)
        result(nil)
    }
    
    private func setGlobalProperty(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let arguments = call.arguments as? [String: Any],
              let key = arguments["key"] as? String else {
            result(FlutterError(code: "INVALID_ARGUMENT", message: "Global property key is required", details: nil))
            return
        }
        
        let value = arguments["value"] as? String ?? ""
        let overrideExisting = arguments["overrideExisting"] as? Bool ?? true
        
        actionQueue.async { [weak self] in
            guard let self = self else { return }
            
            if self.globalProperties[key] != nil && !overrideExisting {
                DispatchQueue.main.async {
                    result(false)
                }
                return
            }
            
            self.globalProperties[key] = value
            os_log("Global property set: %@", log: Self.logger, type: .debug, key)
            
            DispatchQueue.main.async {
                result(true)
            }
        }
    }
    
    private func unsetGlobalProperty(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let arguments = call.arguments as? [String: Any],
              let key = arguments["key"] as? String else {
            result(FlutterError(code: "INVALID_ARGUMENT", message: "Global property key is required", details: nil))
            return
        }
        
        actionQueue.async { [weak self] in
            guard let self = self else { return }
            
            self.globalProperties.removeValue(forKey: key)
            os_log("Global property removed: %@", log: Self.logger, type: .debug, key)
            
            DispatchQueue.main.async {
                result(nil)
            }
        }
    }
    
    private func getGlobalProperties(result: @escaping FlutterResult) {
        actionQueue.async { [weak self] in
            guard let self = self else { return }
            
            os_log("Getting global properties: %d properties", log: Self.logger, type: .debug, self.globalProperties.count)
            
            DispatchQueue.main.async {
                result(self.globalProperties)
            }
        }
    }
    
    private func clearGlobalProperties(result: @escaping FlutterResult) {
        actionQueue.async { [weak self] in
            guard let self = self else { return }
            
            self.globalProperties.removeAll()
            os_log("All global properties cleared", log: Self.logger, type: .debug)
            
            DispatchQueue.main.async {
                result(nil)
            }
        }
    }
    
    private func setTrackingEnabled(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let arguments = call.arguments as? [String: Any],
              let enabled = arguments["enabled"] as? Bool else {
            result(FlutterError(code: "INVALID_ARGUMENT", message: "enabled parameter is required", details: nil))
            return
        }
        
        trackingEnabled = enabled
        os_log("Tracking enabled set to: %@", log: Self.logger, type: .debug, enabled ? "true" : "false")
        result(nil)
    }
    
    private func isTrackingEnabled(result: @escaping FlutterResult) {
        result(trackingEnabled)
    }
    
    private func setDataSharingEnabled(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let arguments = call.arguments as? [String: Any],
              let enabled = arguments["enabled"] as? Bool else {
            result(FlutterError(code: "INVALID_ARGUMENT", message: "enabled parameter is required", details: nil))
            return
        }
        
        dataSharingEnabled = enabled
        os_log("Data sharing enabled set to: %@", log: Self.logger, type: .debug, enabled ? "true" : "false")
        result(nil)
    }
    
    private func isDataSharingEnabled(result: @escaping FlutterResult) {
        result(dataSharingEnabled)
    }
    
    private func trackingOptIn(result: @escaping FlutterResult) {
        trackingEnabled = true
        dataSharingEnabled = true
        allTrackingStopped = false
        os_log("User opted into tracking", log: Self.logger, type: .info)
        result(nil)
    }
    
    private func trackingOptOut(result: @escaping FlutterResult) {
        trackingEnabled = false
        dataSharingEnabled = false
        os_log("User opted out of tracking", log: Self.logger, type: .info)
        result(nil)
    }
    
    private func stopAllTracking(result: @escaping FlutterResult) {
        allTrackingStopped = true
        trackingEnabled = false
        dataSharingEnabled = false
        stopAutoFlush()
        os_log("All tracking stopped", log: Self.logger, type: .info)
        result(nil)
    }
    
    private func resumeAllTracking(result: @escaping FlutterResult) {
        allTrackingStopped = false
        trackingEnabled = true
        dataSharingEnabled = true
        if isInitialized && apiUrl?.isEmpty == false {
            startAutoFlush()
        }
        os_log("All tracking resumed", log: Self.logger, type: .info)
        result(nil)
    }
    
    private func isAllTrackingStopped(result: @escaping FlutterResult) {
        result(allTrackingStopped)
    }
    
    private func setDeviceId(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let arguments = call.arguments as? [String: Any] else {
            result(FlutterError(code: "INVALID_ARGUMENT", message: "Invalid arguments", details: nil))
            return
        }
        
        currentDeviceId = arguments["deviceId"] as? String
        os_log("Device ID set", log: Self.logger, type: .debug)
        result(nil)
    }
    
    private func unsetDeviceId(result: @escaping FlutterResult) {
        currentDeviceId = nil
        os_log("Device ID unset", log: Self.logger, type: .debug)
        result(nil)
    }
    
    private func setSessionTimeout(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let arguments = call.arguments as? [String: Any],
              let timeoutMinutes = arguments["timeoutMinutes"] as? Int else {
            result(FlutterError(code: "INVALID_ARGUMENT", message: "timeoutMinutes parameter is required", details: nil))
            return
        }
        
        sessionTimeoutMinutes = timeoutMinutes
        os_log("Session timeout set to: %d minutes", log: Self.logger, type: .debug, timeoutMinutes)
        result(nil)
    }
    
    // MARK: - iOS SKAdNetwork Support
    
    private func skanRegisterAppForAttribution(result: @escaping FlutterResult) {
        guard skanEnabled else {
            os_log("SKAdNetwork is disabled", log: Self.logger, type: .info)
            result(nil)
            return
        }
        
        if #available(iOS 14.0, *) {
            if #available(iOS 14.5, *) {
                // Request tracking authorization on iOS 14.5+
                ATTrackingManager.requestTrackingAuthorization { status in
                    os_log("Tracking authorization status: %d", log: Self.logger, type: .info, status.rawValue)
                    
                    // Register app for attribution regardless of ATT status
                    SKAdNetwork.registerAppForAdNetworkAttribution()
                    os_log("SKAdNetwork app registered for attribution", log: Self.logger, type: .info)
                    
                    DispatchQueue.main.async {
                        result(nil)
                    }
                }
            } else {
                // iOS 14.0-14.4
                SKAdNetwork.registerAppForAdNetworkAttribution()
                os_log("SKAdNetwork app registered for attribution", log: Self.logger, type: .info)
                result(nil)
            }
        } else {
            os_log("SKAdNetwork not available on iOS < 14.0", log: Self.logger, type: .error)
            result(nil)
        }
    }
    
    private func skanUpdateConversionValue(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let arguments = call.arguments as? [String: Any],
              let newConversionValue = arguments["conversionValue"] as? Int else {
            result(FlutterError(code: "INVALID_ARGUMENT", message: "conversionValue parameter is required", details: nil))
            return
        }
        
        guard newConversionValue >= 0 && newConversionValue <= 63 else {
            result(FlutterError(code: "INVALID_ARGUMENT", message: "SKAdNetwork conversion value must be between 0-63", details: nil))
            return
        }
        
        if #available(iOS 14.0, *) {
            SKAdNetwork.updateConversionValue(newConversionValue)
            conversionValue = newConversionValue
            os_log("SKAdNetwork conversion value updated to: %d", log: Self.logger, type: .info, newConversionValue)
            result(true)
        } else {
            os_log("SKAdNetwork not available on iOS < 14.0", log: Self.logger, type: .error)
            result(false)
        }
    }
    
    private func skanUpdateConversionValues(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let arguments = call.arguments as? [String: Any],
              let newConversionValue = arguments["conversionValue"] as? Int,
              let coarseValue = arguments["coarseValue"] as? Int,
              let lockWindow = arguments["lockWindow"] as? Bool else {
            result(FlutterError(code: "INVALID_ARGUMENT", message: "conversionValue, coarseValue, and lockWindow parameters are required", details: nil))
            return
        }
        
        guard newConversionValue >= 0 && newConversionValue <= 63 else {
            result(FlutterError(code: "INVALID_ARGUMENT", message: "SKAdNetwork conversion value must be between 0-63", details: nil))
            return
        }
        
        guard coarseValue >= 0 && coarseValue <= 2 else {
            result(FlutterError(code: "INVALID_ARGUMENT", message: "SKAdNetwork coarse value must be between 0-2", details: nil))
            return
        }
        
        if #available(iOS 16.1, *) {
            let coarseConversionValue: SKAdNetwork.CoarseConversionValue
            switch coarseValue {
            case 0:
                coarseConversionValue = .low
            case 1:
                coarseConversionValue = .medium
            case 2:
                coarseConversionValue = .high
            default:
                coarseConversionValue = .low
            }
            
            SKAdNetwork.updatePostbackConversionValue(newConversionValue, coarseValue: coarseConversionValue, lockWindow: lockWindow) { error in
                if let error = error {
                    os_log("SKAdNetwork conversion values update failed: %@", log: Self.logger, type: .error, error.localizedDescription)
                } else {
                    os_log("SKAdNetwork conversion values updated: %d, coarse: %d, lock: %@", log: Self.logger, type: .info, newConversionValue, coarseValue, lockWindow ? "true" : "false")
                }
                
                DispatchQueue.main.async {
                    result(nil)
                }
            }
            
            conversionValue = newConversionValue
        } else {
            os_log("SKAdNetwork 4.0 features not available on iOS < 16.1", log: Self.logger, type: .error)
            result(nil)
        }
    }
    
    private func skanGetConversionValue(result: @escaping FlutterResult) {
        result(conversionValue)
    }
    
    // MARK: - Push Notifications & Uninstall Tracking
    
    private func registerDeviceTokenForUninstall(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let arguments = call.arguments as? [String: Any],
              let deviceTokenString = arguments["deviceToken"] as? String else {
            result(FlutterError(code: "INVALID_ARGUMENT", message: "deviceToken parameter is required", details: nil))
            return
        }
        
        deviceToken = deviceTokenString
        os_log("Device token registered for uninstall tracking", log: Self.logger, type: .info)
        result(nil)
    }
    
    private func setFCMDeviceToken(call: FlutterMethodCall, result: @escaping FlutterResult) {
        // FCM is Android-specific functionality
        os_log("FCM device token not applicable on iOS", log: Self.logger, type: .debug)
        result(nil)
    }
    
    private func handlePushNotification(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let arguments = call.arguments as? [String: Any],
              let notificationPayload = arguments["notificationPayload"] as? [String: Any] else {
            result(FlutterError(code: "INVALID_ARGUMENT", message: "notificationPayload parameter is required", details: nil))
            return
        }
        
        actionQueue.async { [weak self] in
            guard let self = self else { return }
            
            os_log("Handling push notification with payload", log: Self.logger, type: .debug)
            
            // Track push notification received
            if self.isEnabled && self.isInitialized && !self.allTrackingStopped {
                var properties: [String: Any] = [
                    "event_name": "push_notification_received",
                    "action_subtype": "push_notification",
                    "notification_payload": notificationPayload,
                    "platform": "ios"
                ]
                properties.merge(self.globalProperties) { (_, new) in new }
                
                let action = UserAction(
                    id: self.generateActionId(),
                    actionType: "custom",
                    screenName: nil,
                    elementId: nil,
                    elementType: "notification",
                    userId: self.currentUserId,
                    sessionId: self.currentSessionId,
                    timestamp: Int64(Date().timeIntervalSince1970 * 1000),
                    properties: properties,
                    deviceInfo: self.createDeviceInfo(),
                    appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
                    sdkVersion: self.sdkVersion
                )
                
                self.userActions.append(action)
                os_log("Push notification tracked: %@", log: Self.logger, type: .debug, action.id)
            }
            
            DispatchQueue.main.async {
                result(nil)
            }
        }
    }
    
    // MARK: - Advanced Configuration
    
    private func setWrapperInfo(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let arguments = call.arguments as? [String: Any],
              let name = arguments["name"] as? String,
              let version = arguments["version"] as? String else {
            result(FlutterError(code: "INVALID_ARGUMENT", message: "name and version parameters are required", details: nil))
            return
        }
        
        wrapperName = name
        wrapperVersion = version
        os_log("Wrapper info set: %@ v%@", log: Self.logger, type: .debug, name, version)
        result(nil)
    }
    
    private func getSdkVersion(result: @escaping FlutterResult) {
        result(sdkVersion)
    }
    
    // MARK: - iOS App Tracking Transparency (ATT) Support
    
    private func requestTrackingPermission(result: @escaping FlutterResult) {
        if #available(iOS 14.5, *) {
            ATTrackingManager.requestTrackingAuthorization { [weak self] status in
                guard let self = self else {
                    DispatchQueue.main.async { result(nil) }
                    return
                }
                
                // Update cached status
                self.cachedATTStatus = status
                
                // Re-collect IDFA now that permission may have changed
                if status == .authorized {
                    let idfa = ASIdentifierManager.shared().advertisingIdentifier.uuidString
                    self.cachedIDFA = idfa == "00000000-0000-0000-0000-000000000000" ? nil : idfa
                    os_log("IDFA re-collected after ATT permission granted: %@", log: Self.logger, type: .info, self.cachedIDFA ?? "nil")
                } else {
                    self.cachedIDFA = nil
                    os_log("IDFA cleared after ATT permission denied/restricted", log: Self.logger, type: .info)
                }
                
                DispatchQueue.main.async {
                    result(nil)
                    os_log("ATT permission request completed with status: %@", log: Self.logger, type: .info, self.attStatusToString(status))
                }
            }
        } else {
            // iOS < 14.5, no ATT available
            os_log("ATT not available on iOS < 14.5, request completed successfully", log: Self.logger, type: .info)
            result(nil)
        }
    }
    
    private func getTrackingAuthorizationStatus(result: @escaping FlutterResult) {
        let statusString: String
        if #available(iOS 14.0, *) {
            statusString = attStatusToString(cachedATTStatus)
        } else {
            statusString = cachedIDFA != nil ? "authorized" : "denied"
        }
        os_log("Current ATT authorization status: %@", log: Self.logger, type: .debug, statusString)
        result(statusString)
    }
    
    private func isTrackingAuthorized(result: @escaping FlutterResult) {
        let isAuthorized: Bool
        if #available(iOS 14.0, *), let attStatus = cachedATTStatus as? ATTrackingManager.AuthorizationStatus {
            isAuthorized = attStatus == .authorized
        } else {
            isAuthorized = cachedIDFA != nil
        }
        os_log("Is tracking authorized: %@", log: Self.logger, type: .debug, String(isAuthorized))
        result(isAuthorized)
    }
    
    private func getIDFA(result: @escaping FlutterResult) {
        os_log("Returning cached IDFA: %@", log: Self.logger, type: .debug, cachedIDFA ?? "nil")
        result(cachedIDFA)
    }
}