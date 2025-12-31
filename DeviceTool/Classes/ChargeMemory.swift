//
//  ChargeMemory.swift
//  PrepareReadyGo
//
//  Created by Account on 24/12/25.
//

import UIKit

// MARK: - PrepareMemoryInfo


class PrepareMemoryInfo {
    

    static func prepareTotalMemoryGB() -> String {
        let physicalBytes = ProcessInfo.processInfo.physicalMemory
        let totalMB = calculateTotalMemoryMB(from: physicalBytes)
        
        if totalMB <= 0 {
            return "-1"
        }
        
        let totalGB = totalMB / 1024.0
        return String(format: "%.6f", totalGB)
    }
    

    static func prepareFreeMemoryGB() -> String {
        let memoryInfo = prepareGetMemoryUsageInfo()
        let freeGB = memoryInfo.freeGB
        return String(format: "%.6f", freeGB)
    }
    

    static func prepareMemoryInfo() -> (totalGB: String, freeGB: String) {
        return (prepareTotalMemoryGB(), prepareFreeMemoryGB())
    }
    
    // MARK: - Private Methods
    



    private static func calculateTotalMemoryMB(from physicalBytes: UInt64) -> Double {
        var totalMB = (Double(physicalBytes) / 1024.0) / 1024.0
        let bucketMB = 256
        let remainder = Int(totalMB) % bucketMB
        
        if remainder >= bucketMB / 2 {
            totalMB = Double(Int(totalMB) - remainder + bucketMB)
        } else {
            totalMB = Double(Int(totalMB) - remainder)
        }
        
        return totalMB
    }
    


    private static func prepareGetMemoryUsageInfo() -> (usedBytes: UInt64, freeGB: Double) {
        var vmInfo = task_vm_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<task_vm_info>.size) / 4
        
        let kern: kern_return_t = withUnsafeMutablePointer(to: &vmInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count)
            }
        }
        
        var usedBytes: UInt64 = 0
        if kern == KERN_SUCCESS {
            usedBytes = UInt64(vmInfo.phys_footprint)
        }
        
        let totalBytes = ProcessInfo.processInfo.physicalMemory
        let freeGB = ((Double(totalBytes - usedBytes) / 1024.0) / 1024.0) / 1024.0
        
        return (usedBytes, freeGB)
    }
}

// MARK: - PrepareDiskInfo


class PrepareDiskInfo {
    

    static func prepareTotalDisk() -> String {
        return prepareFormatDiskSpace(attributeKey: .systemSize)
    }
    

    static func prepareFreeDisk() -> String {
        return prepareFormatDiskSpace(attributeKey: .systemFreeSize)
    }
    

    static func prepareDiskInfo() -> (total: String, free: String) {
        return (prepareTotalDisk(), prepareFreeDisk())
    }
    
    // MARK: - Private Methods
    



    private static func prepareFormatDiskSpace(attributeKey: FileAttributeKey) -> String {
        let size = prepareGetDiskSize(attributeKey: attributeKey)
        return size > 0 ? prepareFormatBytesDisplay(size) : "0"
    }
    



    private static func prepareGetDiskSize(attributeKey: FileAttributeKey) -> Int {
        guard let attrs = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory()) else {
            return -1
        }
        return attrs[attributeKey] as? Int ?? -1
    }
    



    static func prepareFormatBytesDisplay(_ bytes: Int) -> String {
        let bytesD = Double(bytes)
        let gib = bytesD / (1024 * 1024 * 1024)
        let mib = bytesD / (1024 * 1024)
        
        if gib >= 1.0 {
            return String(format: "%.6f", gib)
        }
        
        if mib >= 1.0 {
            return String(format: "%.6f MB", mib)
        }
        
        let formatter = NumberFormatter()
        formatter.positiveFormat = "###,###,###,###"
        return formatter.string(from: NSNumber(integerLiteral: bytes)) ?? "0"
    }
}

// MARK: - Legacy Compatibility (Deprecated)


@available(*, deprecated, message: "Use PrepareMemoryInfo or PrepareDiskInfo instead")
class ChargeMemory: NSObject {
    
    static func totalMemoryGBString() -> String {
        return PrepareMemoryInfo.prepareTotalMemoryGB()
    }
    
    static func freeMemoryGBString() -> String {
        return PrepareMemoryInfo.prepareFreeMemoryGB()
    }
    
    static func totalDiskString() -> String {
        return PrepareDiskInfo.prepareTotalDisk()
    }
    
    static func freeDiskString() -> String {
        return PrepareDiskInfo.prepareFreeDisk()
    }
    
    static func formatBytesDisplay(_ bytes: Int) -> String {
        return PrepareDiskInfo.prepareFormatBytesDisplay(bytes)
    }
}
