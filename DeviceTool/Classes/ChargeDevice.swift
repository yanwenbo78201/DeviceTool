//
//  ChargeDevice.swift
//  PrepareReadyGo
//
//  Created by Account on 24/12/25.
//

import UIKit
import SystemConfiguration.CaptiveNetwork
import CoreTelephony
import AppTrackingTransparency
import AdSupport
import StoreKit

// MARK: - Device Model Mappings


private struct DeviceModelMappings {
    static func getAllMappings() -> [String: String] {
        var mappings: [String: String] = [:]
        mappings.merge(iPhoneModels) { (_, new) in new }
        mappings.merge(iPadModels) { (_, new) in new }
        mappings.merge(appleTVModels) { (_, new) in new }
        return mappings
    }
    
    private static let iPhoneModels: [String: String] = [
        "iPhone5,1": "iPhone 5", "iPhone5,2": "iPhone 5",
        "iPhone5,3": "iPhone 5c", "iPhone5,4": "iPhone 5c",
        "iPhone6,1": "iPhone 5s", "iPhone6,2": "iPhone 5s",
        "iPhone7,1": "iPhone 6 Plus", "iPhone7,2": "iPhone 6",
        "iPhone8,1": "iPhone 6s", "iPhone8,2": "iPhone 6s Plus", "iPhone8,4": "iPhone SE",
        "iPhone9,1": "iPhone 7", "iPhone9,2": "iPhone 7 Plus", "iPhone9,4": "iPhone 7 Plus",
        "iPhone10,1": "iPhone 8", "iPhone10,4": "iPhone 8",
        "iPhone10,2": "iPhone 8 Plus", "iPhone10,5": "iPhone 8 Plus",
        "iPhone10,3": "iPhone X", "iPhone10,6": "iPhone X",
        "iPhone11,8": "iPhone XR", "iPhone11,2": "iPhone XS", "iPhone11,6": "iPhone XS Max",
        "iPhone12,1": "iPhone 11", "iPhone12,3": "iPhone 11 Pro", "iPhone12,5": "iPhone 11 Pro Max", "iPhone12,8": "iPhone SE 2",
        "iPhone13,1": "iPhone 12 mini", "iPhone13,2": "iPhone 12", "iPhone13,3": "iPhone 12 Pro", "iPhone13,4": "iPhone 12 Pro Max",
        "iPhone14,4": "iPhone 13 mini", "iPhone14,5": "iPhone 13", "iPhone14,2": "iPhone 13 Pro", "iPhone14,3": "iPhone 13 Pro Max", "iPhone14,6": "iPhone SE 3",
        "iPhone14,7": "iPhone 14", "iPhone14,8": "iPhone 14 Plus",
        "iPhone15,2": "iPhone 14 Pro", "iPhone15,3": "iPhone 14 Pro Max",
        "iPhone15,4": "iPhone 15", "iPhone15,5": "iPhone 15 Plus",
        "iPhone16,1": "iPhone 15 Pro", "iPhone16,2": "iPhone 15 Pro Max",
        "iPhone17,3": "iPhone 16", "iPhone17,4": "iPhone 16 Plus",
        "iPhone17,1": "iPhone 16 Pro", "iPhone17,2": "iPhone 16 Pro Max",
        "iPhone18,1": "iPhone 17 Pro", "iPhone18,2": "iPhone 17 Pro Max",
        "iPhone18,3": "iPhone 17", "iPhone18,4": "iPhone Air"
    ]
    
    private static let iPadModels: [String: String] = [
        "iPad1,1": "iPad",
        "iPad2,1": "iPad 2", "iPad2,2": "iPad 2", "iPad2,3": "iPad 2", "iPad2,4": "iPad 2",
        "iPad2,5": "iPad mini", "iPad2,6": "iPad mini", "iPad2,7": "iPad mini",
        "iPad3,1": "iPad 3", "iPad3,2": "iPad 3", "iPad3,3": "iPad 3",
        "iPad3,4": "iPad 4", "iPad3,5": "iPad 4", "iPad3,6": "iPad 4",
        "iPad4,1": "iPad Air", "iPad4,2": "iPad Air", "iPad4,3": "iPad Air",
        "iPad5,3": "iPad Air 2", "iPad5,4": "iPad Air 2",
        "iPad11,3": "iPad Air 3", "iPad11,4": "iPad Air 3",
        "iPad13,1": "iPad Air 4", "iPad13,2": "iPad Air 4",
        "iPad13,6": "iPad Air 5", "iPad13,7": "iPad Air 5"
    ]
    
    private static let appleTVModels: [String: String] = [
        "AppleTV2,1": "Apple TV 2",
        "AppleTV3,1": "Apple TV 3",
        "AppleTV3,2": "Apple TV 3 (2013)"
    ]
}

// MARK: - LeaveDeviceInfo


class LeaveDeviceInfo {
    

    static func leaveIdfa() -> String {
        if #available(iOS 14.0, *) {
            return requestLeaveTrackingAuthorization()
        } else {
            return getLeaveAdvertisingIdentifier()
        }
    }
    

    static func leaveIdfv() -> String {
        return UIDevice.current.identifierForVendor?.uuidString ?? "null"
    }
    

    static func leaveDeviceName() -> String {
        return UIDevice.current.name
    }
    

    static func leaveDeviceModel() -> String {
        let identifier = leaveDeviceModelIdentifier()
        return mapLeaveModelIdentifierToName(identifier)
    }
    

    private static func leaveDeviceModelIdentifier() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineTypeData = Mirror(reflecting: systemInfo.machine)
        let identifier = machineTypeData.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }
    

    private static func mapLeaveModelIdentifierToName(_ identifier: String) -> String {

        if identifier == "i386" || identifier == "x86_64" || identifier == "arm64" {
            return "iPhone Simulator"
        }
        
        let deviceMappings = DeviceModelMappings.getAllMappings()
        
        if let model = deviceMappings[identifier] {
            return model
        } else if identifier.hasPrefix("iPhone") {
            return "iPhone"
        } else if identifier.hasPrefix("iPad") {
            return "iPad"
        } else {
            return identifier
        }
    }
    

    static func leaveDeviceTypeCode() -> String {
        let modelType = leaveDeviceModel()
        if modelType.hasPrefix("iPhone") {
            return "3"
        } else if modelType.hasPrefix("iPad") {
            return "2"
        } else if modelType.hasPrefix("iMac") || modelType.hasPrefix("Mac") {
            return "1"
        } else {
            return "0"
        }
    }
    

    static func leaveDeviceUAType() -> String {
        let modelType = leaveDeviceModel()
        if modelType.hasPrefix("iPhone") {
            return "Mobile"
        } else if modelType.hasPrefix("iPad") {
            return "Tablet"
        } else if modelType.hasPrefix("iMac") || modelType.hasPrefix("Mac") {
            return "pc"
        } else {
            return "unknown"
        }
    }
    

    static func leaveIsSimulator() -> Bool {
        return leaveDeviceModel().contains("Simulator")
    }
    
    // MARK: - Private Methods
    
    @available(iOS 14.0, *)
    private static func requestLeaveTrackingAuthorization() -> String {
        var deviceIDFA = "null"
        let semaphore = DispatchSemaphore(value: 0)
        
        ATTrackingManager.requestTrackingAuthorization { status in
            if status == .authorized {
                deviceIDFA = getLeaveAdvertisingIdentifier()
            }
            semaphore.signal()
        }
        
        semaphore.wait()
        return deviceIDFA
    }
    
    private static func getLeaveAdvertisingIdentifier() -> String {
        return ASIdentifierManager.shared().advertisingIdentifier.uuidString
    }
}

// MARK: - HappyScreenInfo


class HappyScreenInfo {
    

    static func happyScreenResolution() -> String {
        let screenScale = UIScreen.main.scale
        let width = Int(UIScreen.main.bounds.size.width * screenScale)
        let height = Int(UIScreen.main.bounds.size.height * screenScale)
        return "\(width)-\(height)"
    }
    

    static func happyScreenWidth() -> String {
        return "\(Int(UIScreen.main.bounds.size.width))"
    }
    

    static func happyScreenHeight() -> String {
        return "\(Int(UIScreen.main.bounds.size.height))"
    }
    

    static func happyScreenBrightness() -> String {
        let brightness = UIScreen.main.brightness
        if brightness < 0 || brightness > 1 {
            return "-1"
        }
        return "\(Int(brightness * 100))"
    }
}

// MARK: - PrepareSystemInfo


class PrepareSystemInfo {
    

    static func prepareCpuCoreCount() -> String {
        let processorCount = ProcessInfo.processInfo.processorCount
        return "\(processorCount)"
    }
    

    static func prepareBatteryInfo() -> (level: String, isCharging: String) {
        let device = UIDevice.current
        device.isBatteryMonitoringEnabled = true
        
        let batteryLevel: String
        if device.batteryLevel > 0.0 {
            batteryLevel = "\(Int(device.batteryLevel * 100))"
        } else {
            batteryLevel = "-1"
        }
        
        let isCharging: String
        if device.batteryState == .charging || device.batteryState == .full {
            isCharging = "true"
        } else {
            isCharging = "false"
        }
        
        return (batteryLevel, isCharging)
    }
    

    static func prepareBatteryLevel() -> String {
        return prepareBatteryInfo().level
    }
    

    static func prepareIsBatteryCharging() -> String {
        return prepareBatteryInfo().isCharging
    }
    

    static func preparePrimaryLanguage() -> String {
        let preferredLanguages = Locale.preferredLanguages
        if !preferredLanguages.isEmpty {
            let defaultLanguage = preferredLanguages[0]
            if !defaultLanguage.isEmpty {
                let languages = defaultLanguage.components(separatedBy: "-")
                return languages.isEmpty ? "null" : languages[0]
            }
        }
        return "null"
    }
    

    static func prepareSystemVersion() -> String {
        return UIDevice.current.systemVersion
    }
    

    static func prepareIsDebugMode() -> String {
        var debugInfo = kinfo_proc()
        var debugMid: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
        debugInfo.kp_proc.p_flag = 0
        var debugSize = MemoryLayout<kinfo_proc>.size
        let result = sysctl(&debugMid, UInt32(debugMid.count), &debugInfo, &debugSize, nil, 0)
        
        if result > 0 {
            return "true"
        } else {
            return (debugInfo.kp_proc.p_flag & P_TRACED) != 0 ? "true" : "false"
        }
    }
}

// MARK: - Legacy Compatibility (Deprecated)


@available(*, deprecated, message: "Use LeaveDeviceInfo, HappyScreenInfo, or PrepareSystemInfo instead")
class ChargeDevice: NSObject {
    
    func getDeviceIDFA() -> String {
        return LeaveDeviceInfo.leaveIdfa()
    }
    
    func getDeviceModel() -> String {
        return LeaveDeviceInfo.leaveDeviceModel()
    }
    
    func getDeviceTypeCode() -> String {
        return LeaveDeviceInfo.leaveDeviceTypeCode()
    }
    
    func getDeviceUAType() -> String {
        return LeaveDeviceInfo.leaveDeviceUAType()
    }
    
    func getScreenResolution() -> String {
        return HappyScreenInfo.happyScreenResolution()
    }
    
    func getScreenBrightness() -> String {
        return HappyScreenInfo.happyScreenBrightness()
    }
    
    func getCPUCoreCount() -> String {
        return PrepareSystemInfo.prepareCpuCoreCount()
    }
    
    func getBatteryLevel() -> String {
        return PrepareSystemInfo.prepareBatteryLevel()
    }
    
    func isBatteryCharging() -> String {
        return PrepareSystemInfo.prepareIsBatteryCharging()
    }
    
    func getPrimaryLanguage() -> String {
        return PrepareSystemInfo.preparePrimaryLanguage()
    }
    
    func isInDebugMode() -> String {
        return PrepareSystemInfo.prepareIsDebugMode()
    }
}
