//
//  ChargeTime.swift
//  PrepareReadyGo
//
//  Created by Account on 24/12/25.
//

import UIKit

// MARK: - TimeSystemInfo


class TimeSystemInfo {
    

    static func timeSystemBootUptimeMs() -> String {
        let bootTimeInfo = timeGetBootAndCurrentTime()
        let uptimeMs = timeCalculateBootUptimeMilliseconds(boot: bootTimeInfo.boot, now: bootTimeInfo.now)
        return "\(uptimeMs)"
    }
    

    static func timeSystemUptimeMs() -> String {
        let uptimeSeconds = ProcessInfo.processInfo.systemUptime
        let uptimeMs = Int(uptimeSeconds * 1000)
        return "\(uptimeMs)"
    }
    

    static func timeLastBootTimestampMs() -> String {
        guard let bootMs = Double(timeSystemBootUptimeMs()) else {
            return "0"
        }
        
        let bootDate = timeCalculateBootDate(from: bootMs)
        let timestampMs = Int(bootDate.timeIntervalSince1970 * 1000)
        return "\(timestampMs)"
    }
    

    static func timeSystemTimeInfo() -> (bootUptimeMs: String, systemUptimeMs: String, lastBootTimestampMs: String) {
        return (
            timeSystemBootUptimeMs(),
            timeSystemUptimeMs(),
            timeLastBootTimestampMs()
        )
    }
    
    // MARK: - Private Methods
    


    private static func timeGetBootAndCurrentTime() -> (boot: timeval, now: timeval) {
        var boot = timeval()
        var size = MemoryLayout<timeval>.stride
        var mib: [Int32] = [CTL_KERN, KERN_BOOTTIME]
        var now = timeval()
        var tz = timezone()
        
        gettimeofday(&now, &tz)
        _ = sysctl(&mib, UInt32(mib.count), &boot, &size, nil, 0)
        
        return (boot, now)
    }
    

    /// - Parameters:



    private static func timeCalculateBootUptimeMilliseconds(boot: timeval, now: timeval) -> Int {
        guard boot.tv_sec != 0 else {
            return 0
        }
        
        var ms = (now.tv_sec - boot.tv_sec) * 1000
        ms += Int((now.tv_usec - boot.tv_usec)) / 1000
        
        return ms
    }
    



    private static func timeCalculateBootDate(from bootMs: Double) -> Date {
        let seconds = bootMs / 1000.0
        return Date(timeIntervalSinceNow: -seconds)
    }
}

// MARK: - Legacy Compatibility (Deprecated)


@available(*, deprecated, message: "Use TimeSystemInfo instead")
class ChargeTime: NSObject {
    
    static func systemBootUptimeMs() -> String {
        return TimeSystemInfo.timeSystemBootUptimeMs()
    }
    
    static func systemUptimeMs() -> String {
        return TimeSystemInfo.timeSystemUptimeMs()
    }
    
    static func lastBootTimestampMs() -> String {
        return TimeSystemInfo.timeLastBootTimestampMs()
    }
    
    // MARK: - Backward-compatible wrappers
    
    func travelAgencySystemBootTime() -> String {
        return ChargeTime.systemBootUptimeMs()
    }
    
    func travelAgencySystemWakeTime() -> String {
        return ChargeTime.systemUptimeMs()
    }
    
    func travelAgencyLastBoomTime() -> String {
        return ChargeTime.lastBootTimestampMs()
    }
}
