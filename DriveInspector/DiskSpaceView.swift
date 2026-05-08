import Cocoa
import AppKit

class DiskButton: NSButton {
    var diskPath: URL?
}

class DiskSpaceViewController: NSViewController {
    private let diskMonitor: DiskMonitor
    private var disks: [DiskInfo] = []
    private var stackView: NSStackView!
    private var scrollView: NSScrollView!
    
    private var aboutView: NSView!
    private var aboutButton: NSButton!
    private var isAboutMode = false
    
    init(diskMonitor: DiskMonitor) {
        self.diskMonitor = diskMonitor
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        // Use Visual Effect View for the background
        let visualEffectView = NSVisualEffectView()
        visualEffectView.blendingMode = .behindWindow
        visualEffectView.state = .active
        visualEffectView.material = .popover
        self.view = visualEffectView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupAboutView()
        setupAboutButton()
        refreshData()
    }
    
    private func setupUI() {
        scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.drawsBackground = false
        
        stackView = NSStackView()
        stackView.orientation = .vertical
        stackView.spacing = 16
        stackView.edgeInsets = NSEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        stackView.alignment = .centerX
        stackView.distribution = .fill
        
        scrollView.documentView = stackView
        
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            stackView.widthAnchor.constraint(equalToConstant: 300)
        ])
    }
    
    private func setupAboutButton() {
        let config = NSImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        let icon = NSImage(systemSymbolName: "info.circle", accessibilityDescription: "About")?
            .withSymbolConfiguration(config)
        
        aboutButton = NSButton(image: icon ?? NSImage(), target: self, action: #selector(toggleAbout))
        aboutButton.bezelStyle = .shadowlessSquare
        aboutButton.isBordered = false
        aboutButton.contentTintColor = .secondaryLabelColor
        
        view.addSubview(aboutButton)
        aboutButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            aboutButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 12),
            aboutButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            aboutButton.widthAnchor.constraint(equalToConstant: 24),
            aboutButton.heightAnchor.constraint(equalToConstant: 24)
        ])
    }

    private func setupAboutView() {
        aboutView = NSView()
        aboutView.isHidden = true
        view.addSubview(aboutView)
        aboutView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            aboutView.topAnchor.constraint(equalTo: view.topAnchor),
            aboutView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            aboutView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            aboutView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        let container = NSStackView()
        container.orientation = .vertical
        container.spacing = 12
        container.edgeInsets = NSEdgeInsets(top: 40, left: 30, bottom: 30, right: 30)
        container.alignment = .centerX
        
        aboutView.addSubview(container)
        container.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: aboutView.topAnchor),
            container.leadingAnchor.constraint(equalTo: aboutView.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: aboutView.trailingAnchor),
            container.bottomAnchor.constraint(equalTo: aboutView.bottomAnchor)
        ])
        
        let titleLabel = NSTextField(labelWithString: "DriveInspector")
        titleLabel.font = NSFont.systemFont(ofSize: 20, weight: .bold)
        titleLabel.textColor = .labelColor
        
        let versionLabel = NSTextField(labelWithString: "Version 1.0.0")
        versionLabel.font = NSFont.systemFont(ofSize: 11, weight: .medium)
        versionLabel.textColor = .secondaryLabelColor
        
        let authorLabel = NSTextField(labelWithString: "Developed by George Karagioules")
        authorLabel.font = NSFont.systemFont(ofSize: 13, weight: .semibold)
        authorLabel.textColor = .labelColor
        
        let separator = NSView()
        separator.wantsLayer = true
        separator.layer?.backgroundColor = NSColor.separatorColor.cgColor
        separator.translatesAutoresizingMaskIntoConstraints = false
        separator.heightAnchor.constraint(equalToConstant: 1).isActive = true
        separator.widthAnchor.constraint(equalToConstant: 200).isActive = true
        
        let eulaTitle = NSTextField(labelWithString: "End User License Agreement")
        eulaTitle.font = NSFont.systemFont(ofSize: 12, weight: .bold)
        
        let eulaScrollView = NSScrollView()
        eulaScrollView.hasVerticalScroller = true
        eulaScrollView.drawsBackground = false
        eulaScrollView.translatesAutoresizingMaskIntoConstraints = false
        
        let eulaText = """
        DRIVEINSPECTOR FREEWARE LICENSE

        Copyright (c) 2026 George Karagioules.
        All rights reserved.

        1. LICENSE GRANT
        You may download and use DriveInspector free of charge for personal and commercial use.

        2. OWNERSHIP
        DriveInspector and its original source code, design, and assets remain the property of George Karagioules.

        3. RESTRICTIONS
        You may not modify, reverse-engineer, redistribute, sublicense, rent, lease, resell, or sell DriveInspector or any portion of it without prior written permission from the author.

        4. PRIVACY AND DATA
        DriveInspector reads local mounted-volume capacity information through macOS system APIs. It does not collect telemetry, send analytics, sync data, or transmit drive information over the network.

        5. WARRANTY DISCLAIMER
        The software is provided "AS IS", without warranty of any kind, express or implied, including warranties of merchantability, fitness for a particular purpose, and noninfringement.

        6. LIMITATION OF LIABILITY
        In no event shall the author be liable for any claim, damages, data loss, business interruption, or other liability arising from use of the software.

        7. TERMINATION
        This license terminates automatically if you violate its terms. Upon termination, stop using and delete all copies of the software.

        8. GOVERNING LAW
        This license is governed by the laws of the author's jurisdiction, unless mandatory local law requires otherwise.

        9. CONTACT
        For licensing inquiries, including modification, redistribution, or resale rights, contact the author through:
        https://github.com/karagioules/OSX_Drive_Inspector
        """
        
        let textView = NSTextView()
        textView.string = eulaText
        textView.isEditable = false
        textView.backgroundColor = .clear
        textView.textColor = .secondaryLabelColor
        textView.font = NSFont.monospacedSystemFont(ofSize: 10, weight: .regular)
        textView.textContainerInset = NSSize(width: 5, height: 5)
        
        eulaScrollView.documentView = textView
        
        container.addArrangedSubview(titleLabel)
        container.addArrangedSubview(versionLabel)
        container.addArrangedSubview(authorLabel)
        container.addArrangedSubview(separator)
        container.addArrangedSubview(eulaTitle)
        container.addArrangedSubview(eulaScrollView)
        
        NSLayoutConstraint.activate([
            eulaScrollView.widthAnchor.constraint(equalTo: container.widthAnchor, constant: -40),
            eulaScrollView.heightAnchor.constraint(equalToConstant: 180)
        ])
    }
    
    @objc private func toggleAbout() {
        isAboutMode.toggle()
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.25
            context.allowsImplicitAnimation = true
            
            self.scrollView.alphaValue = self.isAboutMode ? 0 : 1
            self.aboutView.alphaValue = self.isAboutMode ? 1 : 0
            
            // Wait for alpha to finish or just toggle visibility
            if !self.isAboutMode {
                self.scrollView.isHidden = false
            } else {
                self.aboutView.isHidden = false
            }
        } completionHandler: {
            self.scrollView.isHidden = self.isAboutMode
            self.aboutView.isHidden = !self.isAboutMode
        }
        
        let iconName = isAboutMode ? "chevron.left.circle.fill" : "info.circle"
        let config = NSImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        aboutButton.image = NSImage(systemSymbolName: iconName, accessibilityDescription: "Toggle About")?
            .withSymbolConfiguration(config)
        
        if isAboutMode {
            aboutButton.contentTintColor = .systemBlue
        } else {
            aboutButton.contentTintColor = .secondaryLabelColor
        }
    }
    
    func refreshData() {
        guard isViewLoaded else { return }
        disks = diskMonitor.getAllDisks()
        updateUI()
    }
    
    private func updateUI() {
        guard let stackView = stackView else { return }
        
        // Properly remove old views
        for subview in stackView.arrangedSubviews {
            stackView.removeArrangedSubview(subview)
            subview.removeFromSuperview()
        }
        
        // Header
        let headerLabel = NSTextField(labelWithString: "Disk Storage")
        headerLabel.font = NSFont.systemFont(ofSize: 13, weight: .bold)
        headerLabel.textColor = .secondaryLabelColor
        stackView.addArrangedSubview(headerLabel)
        headerLabel.alignment = .left
        headerLabel.translatesAutoresizingMaskIntoConstraints = false
        headerLabel.leadingAnchor.constraint(equalTo: stackView.leadingAnchor, constant: 20).isActive = true
        
        for disk in disks {
            let diskView = createDiskView(for: disk)
            stackView.addArrangedSubview(diskView)
        }
        
        if disks.isEmpty {
            let noDisksLabel = NSTextField(labelWithString: "No disks found")
            noDisksLabel.textColor = .secondaryLabelColor
            noDisksLabel.font = NSFont.systemFont(ofSize: 14)
            stackView.addArrangedSubview(noDisksLabel)
        }

        // Add flexible spacer
        let spacer = NSView()
        stackView.addArrangedSubview(spacer)
        
        // Footer buttons
        let footerStack = NSStackView()
        footerStack.orientation = .horizontal
        footerStack.alignment = .centerY
        
        let quitButton = NSButton(title: "Quit App", target: self, action: #selector(quitApp))
        quitButton.bezelStyle = .rounded
        quitButton.controlSize = .small
        
        footerStack.addArrangedSubview(NSView()) // Spacer
        footerStack.addArrangedSubview(quitButton)
        
        stackView.addArrangedSubview(footerStack)
        footerStack.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            footerStack.leadingAnchor.constraint(equalTo: stackView.leadingAnchor, constant: 20),
            footerStack.trailingAnchor.constraint(equalTo: stackView.trailingAnchor, constant: -20),
            footerStack.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        // Force layout and set preferred size for popover expansion
        stackView.layoutSubtreeIfNeeded()
        let fittingSize = stackView.fittingSize
        self.preferredContentSize = NSSize(width: 300, height: min(600, fittingSize.height))
    }
    
    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }

    @objc private func manualRefresh() {
        refreshData()
    }

    @objc private func openInFinder(_ sender: DiskButton) {
        if let diskPath = sender.diskPath {
            NSWorkspace.shared.open(diskPath)
        }
    }
    
    private func createDiskView(for disk: DiskInfo) -> NSView {
        let containerView = NSView()
        containerView.wantsLayer = true
        containerView.layer?.backgroundColor = NSColor.textColor.withAlphaComponent(0.05).cgColor
        containerView.layer?.cornerRadius = 12
        containerView.layer?.borderWidth = 0.5
        containerView.layer?.borderColor = NSColor.separatorColor.cgColor
        
        // Disk Icon
        let iconName = disk.isExternal ? "externaldrive.fill" : "internaldrive.fill"
        let iconImage = NSImage(systemSymbolName: iconName, accessibilityDescription: nil)?
            .withSymbolConfiguration(NSImage.SymbolConfiguration(pointSize: 22, weight: .regular))
        let iconView = NSImageView(image: iconImage ?? NSImage())
        iconView.contentTintColor = disk.isExternal ? .systemOrange : .systemBlue
        
        let titleLabel = NSTextField(labelWithString: disk.name)
        titleLabel.font = NSFont.systemFont(ofSize: 14, weight: .semibold)
        titleLabel.textColor = .labelColor
        titleLabel.lineBreakMode = .byTruncatingTail
        
        let freeSpace = diskMonitor.formatBytes(disk.freeSpace)
        let totalSpace = diskMonitor.formatBytes(disk.totalCapacity)
        let infoLabel = NSTextField(labelWithString: "\(freeSpace) available of \(totalSpace)")
        infoLabel.font = NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .medium)
        infoLabel.textColor = .secondaryLabelColor
        
        let graphView = DiskGraphView(disk: disk)
        
        let finderIcon = NSImage(systemSymbolName: "arrow.right.circle.fill", accessibilityDescription: "Finder")?
            .withSymbolConfiguration(NSImage.SymbolConfiguration(pointSize: 16, weight: .bold))
        let finderButton = DiskButton(image: finderIcon ?? NSImage(), target: self, action: #selector(openInFinder(_:)))
        finderButton.bezelStyle = .shadowlessSquare
        finderButton.isBordered = false
        finderButton.controlSize = .small
        finderButton.diskPath = disk.path
        finderButton.toolTip = "Open in Finder"
        finderButton.contentTintColor = .tertiaryLabelColor
        
        // Layout
        containerView.addSubview(iconView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(infoLabel)
        containerView.addSubview(graphView)
        containerView.addSubview(finderButton)
        
        iconView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        infoLabel.translatesAutoresizingMaskIntoConstraints = false
        graphView.translatesAutoresizingMaskIntoConstraints = false
        finderButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 14),
            iconView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 14),
            iconView.widthAnchor.constraint(equalToConstant: 28),
            iconView.heightAnchor.constraint(equalToConstant: 28),
            
            titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 14),
            titleLabel.trailingAnchor.constraint(equalTo: finderButton.leadingAnchor, constant: -8),
            
            infoLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            infoLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2),
            infoLabel.trailingAnchor.constraint(equalTo: finderButton.leadingAnchor, constant: -8),
            
            finderButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -14),
            finderButton.centerYAnchor.constraint(equalTo: iconView.centerYAnchor),
            finderButton.widthAnchor.constraint(equalToConstant: 18),
            finderButton.heightAnchor.constraint(equalToConstant: 18),
            
            graphView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 14),
            graphView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -14),
            graphView.topAnchor.constraint(equalTo: infoLabel.bottomAnchor, constant: 12),
            graphView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -14),
            graphView.heightAnchor.constraint(equalToConstant: 12)
        ])
        
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.widthAnchor.constraint(equalToConstant: 260).isActive = true
        
        return containerView
    }
}

class DiskGraphView: NSView {
    private let disk: DiskInfo
    
    init(disk: DiskInfo) {
        self.disk = disk
        super.init(frame: .zero)
        self.wantsLayer = true
        self.layer?.cornerRadius = 6
        self.layer?.masksToBounds = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        let bounds = self.bounds
        let cornerRadius: CGFloat = bounds.height / 2
        
        // Background Track
        let bgPath = NSBezierPath(roundedRect: bounds, xRadius: cornerRadius, yRadius: cornerRadius)
        NSColor.textColor.withAlphaComponent(0.1).set()
        bgPath.fill()
        
        // Used space with gradient
        let usedWidth = bounds.width * disk.usagePercentage
        if usedWidth > 0 {
            let usedRect = NSRect(x: 0, y: 0, width: max(usedWidth, bounds.height), height: bounds.height)
            let usedPath = NSBezierPath(roundedRect: usedRect, xRadius: cornerRadius, yRadius: cornerRadius)
            
            let color1: NSColor
            let color2: NSColor
            
            if disk.usagePercentage > 0.9 {
                color1 = .systemRed
                color2 = NSColor(calibratedRed: 1.0, green: 0.3, blue: 0.3, alpha: 1.0)
            } else if disk.usagePercentage > 0.75 {
                color1 = .systemOrange
                color2 = NSColor(calibratedRed: 1.0, green: 0.7, blue: 0.2, alpha: 1.0)
            } else {
                color1 = .systemBlue
                color2 = NSColor(calibratedRed: 0.3, green: 0.6, blue: 1.0, alpha: 1.0)
            }
            
            let gradient = NSGradient(starting: color1, ending: color2)
            gradient?.draw(in: usedPath, angle: 0)
            
            // Subtle gloss
            let glossRect = NSRect(x: 0, y: 0, width: usedRect.width, height: bounds.height / 2)
            let glossPath = NSBezierPath(roundedRect: glossRect, xRadius: cornerRadius, yRadius: cornerRadius)
            NSColor.white.withAlphaComponent(0.1).set()
            glossPath.fill()
        }
    }
}
