//
//  ChargeNetwork.swift
//  PrepareReadyGo
//
//  Created by Account on 24/12/25.
//

import UIKit
import SystemConfiguration.CaptiveNetwork
import CoreTelephony

// MARK: - PrepareNetworkType


class PrepareNetworkType {
    

    static func prepareNetworkCategoryCode() -> String {
        let detailType = prepareNetworkDetailType()
        return prepareConvertDetailTypeToCode(detailType)
    }
    

    static func prepareNetworkDetailType() -> String {
        let reachability = prepareCreateReachability()
        var flags: SCNetworkReachabilityFlags = []
        
        guard prepareGetReachabilityFlags(reachability, &flags) else {
            return "Unknown"
        }
        
        guard prepareIsNetworkReachable(flags) else {
            return "notReachable"
        }
        
        if prepareIsWWAN(flags) {
            return prepareMobileRadioAccessType()
        }
        
        return "WiFi"
    }
    

    static func prepareMobileRadioAccessType() -> String {
        let telephony = CTTelephonyNetworkInfo()
        let radio = prepareGetCurrentRadioAccessTechnology(telephony: telephony)
        
        guard !radio.isEmpty else {
            return "notReachable"
        }
        
        return prepareParseRadioAccessTechnology(radio)
    }
    
    // MARK: - Private Methods
    

    private static func prepareCreateReachability() -> SCNetworkReachability? {
        var addr = sockaddr_in()
        addr.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        addr.sin_family = sa_family_t(AF_INET)
        return withUnsafePointer(to: &addr) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { zeroSockAddress in
                SCNetworkReachabilityCreateWithAddress(nil, zeroSockAddress)
            }
        }
    }
    

    private static func prepareGetReachabilityFlags(_ reachability: SCNetworkReachability?, _ flags: inout SCNetworkReachabilityFlags) -> Bool {
        guard let reachability = reachability else { return false }
        return SCNetworkReachabilityGetFlags(reachability, &flags)
    }
    

    private static func prepareIsNetworkReachable(_ flags: SCNetworkReachabilityFlags) -> Bool {
        let reachable = flags.contains(.reachable)
        let needsConnection = flags.contains(.connectionRequired)
        return reachable && !needsConnection
    }
    

    private static func prepareIsWWAN(_ flags: SCNetworkReachabilityFlags) -> Bool {
        return flags.contains(.isWWAN)
    }
    

    private static func prepareGetCurrentRadioAccessTechnology(telephony: CTTelephonyNetworkInfo) -> String {
        if #available(iOS 12.1, *) {
            if let dict = telephony.serviceCurrentRadioAccessTechnology,
               let key = Array(dict.keys).first,
               key.count > 0 {
                return dict[key] ?? ""
            }
        } else {
            return telephony.currentRadioAccessTechnology ?? ""
        }
        return ""
    }
    

    private static func prepareParseRadioAccessTechnology(_ radio: String) -> String {
        if #available(iOS 14.1, *) {
            if radio == CTRadioAccessTechnologyNRNSA || radio == CTRadioAccessTechnologyNR {
                return "5G"
            }
        }
        
        if radio == CTRadioAccessTechnologyLTE {
            return "4G"
        }
        
        let threeGTechnologies = [
            CTRadioAccessTechnologyWCDMA,
            CTRadioAccessTechnologyHSDPA,
            CTRadioAccessTechnologyHSUPA,
            CTRadioAccessTechnologyCDMAEVDORev0,
            CTRadioAccessTechnologyCDMAEVDORevA,
            CTRadioAccessTechnologyCDMAEVDORevB,
            CTRadioAccessTechnologyeHRPD
        ]
        
        if threeGTechnologies.contains(radio) {
            return "3G"
        }
        
        let twoGTechnologies = [
            CTRadioAccessTechnologyEdge,
            CTRadioAccessTechnologyGPRS,
            CTRadioAccessTechnologyCDMA1x
        ]
        
        if twoGTechnologies.contains(radio) {
            return "2G"
        }
        
        return "notReachable"
    }
    

    private static func prepareConvertDetailTypeToCode(_ detailType: String) -> String {
        switch detailType {
        case "Unknown":
            return "0"
        case "WiFi":
            return "1"
        case "2G":
            return "2"
        case "3G":
            return "3"
        case "4G":
            return "4"
        case "5G":
            return "5"
        default:
            return "0"
        }
    }
}

// MARK: - PrepareNetworkSecurity


class PrepareNetworkSecurity {
    

    static func prepareIsVPNEnabled() -> Bool {
        guard let settings = CFNetworkCopySystemProxySettings()?.takeRetainedValue() as? [String: Any] else {
            return false
        }
        
        guard let scoped = settings["__SCOPED__"] as? [String: Any] else {
            return false
        }
        
        return prepareCheckVPNKeywords(in: scoped)
    }
    

    static func prepareIsProxyEnabled() -> Bool {
        guard let settings = CFNetworkCopySystemProxySettings()?.takeRetainedValue() else {
            return false
        }
        
        let testURL = URL(string: "https://www.apple.com")!
        let proxies = CFNetworkCopyProxiesForURL(testURL as CFURL, settings).takeRetainedValue() as NSArray
        
        guard proxies.count > 0,
              let first = proxies.object(at: 0) as? NSDictionary,
              let type = first.object(forKey: kCFProxyTypeKey) as? String else {
            return false
        }
        
        return type != "kCFProxyTypeNone"
    }
    

    static func prepareNetworkSecurityInfo() -> (vpnEnabled: Bool, proxyEnabled: Bool) {
        return (prepareIsVPNEnabled(), prepareIsProxyEnabled())
    }
    
    // MARK: - Private Methods
    

    private static func prepareCheckVPNKeywords(in scoped: [String: Any]) -> Bool {
        let vpnKeywords = ["tap", "tun", "ipsec", "ppp"]
        for key in scoped.keys {
            let lowerKey = key.lowercased()
            if vpnKeywords.contains(where: { lowerKey.contains($0) }) {
                return true
            }
        }
        return false
    }
}

// MARK: - PrepareWiFiInfo


class PrepareWiFiInfo {
    

    static func prepareWiFiInfo() -> [String: String]? {
        guard let interfaces = CNCopySupportedInterfaces() as NSArray? else {
            return nil
        }
        
        for interface in interfaces {
            if let interfaceString = interface as? String,
               let info = CNCopyCurrentNetworkInfo(interfaceString as CFString) as? [String: String] {
                return info
            }
        }
        
        return nil
    }
    

    static func prepareWiFiSSID() -> String? {
        return prepareWiFiInfo()?["ssid"]
    }
    

    static func prepareWiFiBSSID() -> String? {
        return prepareWiFiInfo()?["bssid"]
    }
}

// MARK: - Legacy Compatibility (Deprecated)


@available(*, deprecated, message: "Use PrepareNetworkType, PrepareNetworkSecurity, or PrepareWiFiInfo instead")
class ChargeNetwork: NSObject {
    
    static func networkCategoryCode() -> String {
        return PrepareNetworkType.prepareNetworkCategoryCode()
    }
    
    static func networkDetailType() -> String {
        return PrepareNetworkType.prepareNetworkDetailType()
    }
    
    static func mobileRadioAccessType() -> String {
        return PrepareNetworkType.prepareMobileRadioAccessType()
    }
    
    static func vpnEnabled() -> Bool {
        return PrepareNetworkSecurity.prepareIsVPNEnabled()
    }
    
    static func proxyEnabled() -> Bool {
        return PrepareNetworkSecurity.prepareIsProxyEnabled()
    }
    
    static func wifiInfo() -> [String: String]? {
        return PrepareWiFiInfo.prepareWiFiInfo()
    }
    
    // MARK: - Backward-compatible wrappers
    
    func travelAgencyVPNOpenStatus() -> String {
        return ChargeNetwork.vpnEnabled() ? "true" : "false"
    }
    
    func travelAgencyPoxyStatus() -> String {
        return ChargeNetwork.proxyEnabled() ? "true" : "false"
    }
    
    func travelAgencyCurrentNetworkNumType() -> String {
        return ChargeNetwork.networkCategoryCode()
    }
    
    func travelAgencyCurrentNetworkDetailType() -> String {
        return ChargeNetwork.networkDetailType()
    }
    
    func travelAgencyCurrentMobileNetworType() -> String {
        return ChargeNetwork.mobileRadioAccessType()
    }
    
    func travelAgencyWiFiDetailData() -> [String: String]? {
        return ChargeNetwork.wifiInfo()
    }
}
