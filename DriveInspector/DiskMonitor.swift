import Foundation
import IOKit

struct DiskInfo {
    let name: String
    let path: URL
    let totalCapacity: Int64
    let freeSpace: Int64
    let usedSpace: Int64
    let isExternal: Bool
    let fileSystem: String
    
    var usagePercentage: Double {
        guard totalCapacity > 0 else { return 0 }
        let clampedUsedSpace = min(max(usedSpace, 0), totalCapacity)
        return Double(clampedUsedSpace) / Double(totalCapacity)
    }
    
    var freePercentage: Double {
        guard totalCapacity > 0 else { return 0 }
        let clampedFreeSpace = min(max(freeSpace, 0), totalCapacity)
        return Double(clampedFreeSpace) / Double(totalCapacity)
    }
}

extension Notification.Name {
    static let diskSpaceDidChange = Notification.Name("diskSpaceDidChange")
}

class DiskMonitor: NSObject {
    private var timer: Timer?
    private var lastDisks: [DiskInfo] = []
    
    func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.checkForChanges()
        }
        checkForChanges()
    }
    
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
    
    func getAllDisks() -> [DiskInfo] {
        let keys: [URLResourceKey] = [
            .volumeNameKey,
            .volumeTotalCapacityKey,
            .volumeAvailableCapacityKey,
            .volumeAvailableCapacityForImportantUsageKey,
            .volumeIsRemovableKey,
            .volumeIsInternalKey,
            .volumeIsLocalKey,
            .volumeIsEjectableKey,
            .volumeTypeNameKey,
            .volumeIsAutomountedKey,
            .volumeIsReadOnlyKey
        ]
        
        let fileManager = FileManager.default
        var disks: [DiskInfo] = []
        
        if let volumes = fileManager.mountedVolumeURLs(includingResourceValuesForKeys: keys, options: [.skipHiddenVolumes]) {
            for volumeURL in volumes {
                do {
                    let resourceValues = try volumeURL.resourceValues(forKeys: Set(keys))
                    
                    guard let name = resourceValues.volumeName,
                          let totalCapacity = resourceValues.volumeTotalCapacity else {
                        continue
                    }
                    
                    // Calculate free space by taking the maximum of available capacity and important usage capacity.
                    // This handles cases like backup drives where 'important usage' might report 0
                    // while physical space is still available.
                    let rawFree = Int64(resourceValues.volumeAvailableCapacity ?? 0)
                    let importantFree = resourceValues.volumeAvailableCapacityForImportantUsage ?? 0
                    let freeSpace = max(0, min(Int64(totalCapacity), max(rawFree, importantFree)))
                    
                    // Filter logic:
                    let isInternal = resourceValues.volumeIsInternal ?? false
                    let isLocal = resourceValues.volumeIsLocal ?? false
                    let isReadOnly = resourceValues.volumeIsReadOnly ?? false
                    let isAutomounted = resourceValues.volumeIsAutomounted ?? false
                    
                    let path = volumeURL.path
                    
                    // Skip read-only volumes (likely DMGs or system recovery)
                    if isReadOnly && !isInternal { continue }
                    
                    // Skip automounted/virtual stuff
                    if isAutomounted { continue }
                    
                    // Only include internal OR external physical disks
                    let isPhysicalExternal = isLocal && !isInternal && path.hasPrefix("/Volumes/")
                    
                    if !isInternal && !isPhysicalExternal {
                        continue
                    }
                    
                    let usedSpace = Int64(totalCapacity) - freeSpace
                    let diskInfo = DiskInfo(
                        name: name,
                        path: volumeURL,
                        totalCapacity: Int64(totalCapacity),
                        freeSpace: freeSpace,
                        usedSpace: usedSpace,
                        isExternal: !isInternal,
                        fileSystem: resourceValues.volumeTypeName ?? "Unknown"
                    )
                    
                    disks.append(diskInfo)
                } catch {
                    continue
                }
            }
        }
        
        return disks.sorted { (d1, d2) -> Bool in
            if d1.isExternal != d2.isExternal {
                return !d1.isExternal // Internal first
            }
            return d1.name < d2.name
        }
    }
    
    private func checkForChanges() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            let currentDisks = self.getAllDisks()
            
            DispatchQueue.main.async {
                if currentDisks.count != self.lastDisks.count || 
                   !currentDisks.elementsEqual(self.lastDisks, by: { lhs, rhs in
                       lhs.path == rhs.path &&
                       lhs.name == rhs.name &&
                       lhs.totalCapacity == rhs.totalCapacity &&
                       lhs.freeSpace == rhs.freeSpace &&
                       lhs.usedSpace == rhs.usedSpace &&
                       lhs.isExternal == rhs.isExternal
                   }) {
                    self.lastDisks = currentDisks
                    NotificationCenter.default.post(name: .diskSpaceDidChange, object: nil)
                }
            }
        }
    }
    
    func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useBytes, .useKB, .useMB, .useGB, .useTB]
        formatter.countStyle = .file // .file uses decimal (1000) for macOS 10.12+
        formatter.includesUnit = true
        return formatter.string(fromByteCount: bytes)
    }
}
