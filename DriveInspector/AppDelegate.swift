import Cocoa
import AppKit
import OSLog

class AppDelegate: NSObject, NSApplicationDelegate {
    static var shared: AppDelegate!
    
    var statusItem: NSStatusItem!
    var diskMonitor: DiskMonitor!
    var popover: NSPopover!

    private let logger = Logger(subsystem: "com.karagioules.DriveInspector", category: "App")

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        AppDelegate.shared = self
        logger.info("DriveInspector: applicationDidFinishLaunching started")
        setupMenuBar()
        setupDiskMonitor()
        setupPopover()
        logger.info("DriveInspector: setup completed")
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(diskSpaceChanged),
            name: .diskSpaceDidChange,
            object: nil
        )
        
        updateStatusBarIcon()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        statusItem = nil
    }
    
    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.action = #selector(togglePopover(_:))
        statusItem.button?.target = self
        logger.info("MenuBar setup done")
    }
    
    private func setupDiskMonitor() {
        diskMonitor = DiskMonitor()
        diskMonitor.startMonitoring()
    }
    
    private func setupPopover() {
        popover = NSPopover()
        popover.contentSize = NSSize(width: 300, height: 350)
        popover.behavior = .transient
        popover.contentViewController = DiskSpaceViewController(diskMonitor: diskMonitor)
    }
    
    @objc private func togglePopover(_ sender: Any?) {
        if popover.isShown {
            popover.performClose(sender)
        } else {
            if let button = statusItem.button {
                // Ensure data is fresh AND view is loaded before showing
                if let vc = popover.contentViewController as? DiskSpaceViewController {
                    _ = vc.view // Force view load
                    vc.refreshData()
                }

                // Force the app to the front
                NSApp.activate(ignoringOtherApps: true)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                    guard let self = self else { return }
                    
                    self.popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                    
                    // Force the popover window to be key and at the front
                    if let popoverWindow = self.popover.contentViewController?.view.window {
                        popoverWindow.makeKeyAndOrderFront(nil)
                    }
                }
            }
        }
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        togglePopover(nil)
        return true
    }
    
    @objc private func diskSpaceChanged() {
        updateStatusBarIcon()
        if let viewController = popover.contentViewController as? DiskSpaceViewController {
            viewController.refreshData()
        }
    }
    
    private func updateStatusBarIcon() {
        let disks = diskMonitor.getAllDisks()
        let startupPath = URL(fileURLWithPath: "/").standardizedFileURL.path
        
        // Target the startup disk first; fall back to the first internal disk if needed.
        if let startupDisk = disks.first(where: { $0.path.standardizedFileURL.path == startupPath }) {
            statusItem.button?.title = String(format: "💾 %.0f%%", startupDisk.freePercentage * 100)
            return
        }
        
        if let internalDisk = disks.first(where: { !$0.isExternal }) {
            statusItem.button?.title = String(format: "💾 %.0f%%", internalDisk.freePercentage * 100)
            return
        }
        
        // Fallback to aggregate free percentage if no internal or startup disk is found.
        let totalFree = disks.reduce(0) { $0 + $1.freeSpace }
        let totalCapacity = disks.reduce(0) { $0 + $1.totalCapacity }
        
        if totalCapacity > 0 {
            let percentage = Double(totalFree) / Double(totalCapacity)
            statusItem.button?.title = String(format: "💾 %.0f%%", percentage * 100)
        } else {
            statusItem.button?.title = "💾"
        }
    }
}
