<p align="center">
  <img src="Logo/DiskSpaceAnalyzerIcon.png" alt="DriveInspector app icon" width="180">
</p>

<h1 align="center">Mac Disk Peek</h1>

<p align="center">
  <strong>Open-source macOS menu bar drive-space monitoring.</strong><br>
  <em>See free space at a glance, inspect mounted volumes, and jump straight to Finder.</em>
</p>

<p align="center">
  <a href="https://github.com/gkaragioul/Mac_Disk_Peek/releases/latest"><strong>Download latest app</strong></a> &bull;
  <a href="#highlights">Highlights</a> &bull;
  <a href="#download">Download</a> &bull;
  <a href="#build">Build</a> &bull;
  <a href="#privacy-and-data">Privacy</a> &bull;
  <a href="#license">License</a>
</p>

---

DriveInspector is a native macOS menu bar app that monitors mounted drives and gives a quick view of disk availability.

## Download

Download the latest packaged app bundle here:

**[Download DriveInspector.zip](https://github.com/gkaragioul/Mac_Disk_Peek/releases/latest)**

That link always points to the newest GitHub release.

## Highlights

- Menu bar badge showing the free percentage for the startup drive
- Live disk list with internal and external volumes
- Per-disk capacity cards with usage bars
- Finder shortcut for each mounted volume
- Lightweight native AppKit UI
- No telemetry, analytics, account system, or network sync

## Latest Improvements

- Added a downloadable GitHub release asset with a permanent latest-download link
- Fixed first-open popover sizing so the window matches the connected drive count immediately
- Restored the app bundle icon in exported builds
- Fixed status badge logic to use the startup drive instead of a generic internal disk
- Switched badge semantics to show free percentage instead of used percentage
- Added safer capacity math to avoid invalid percentage edge cases
- Improved disk change detection for more reliable UI refreshes
- Cleaned app icon asset set with correctly sized icon files for macOS slots

## Build

### Requirements

- macOS 13.0+
- Xcode 15+

### Local Build

```bash
git clone https://github.com/gkaragioul/Mac_Disk_Peek.git
cd Mac_Disk_Peek
xcodebuild -project DriveInspector.xcodeproj -scheme DriveInspector -configuration Release build
```

Build outputs are intentionally excluded from source control. If you redistribute a built copy, include `LICENSE` with the app or installer so users receive the MIT license terms before download or install.

## Project

- Language: Swift
- UI: AppKit
- Entry point: `DriveInspector/main.swift`
- Runtime dependencies: Apple system frameworks only

## Privacy and data

DriveInspector reads local mounted-volume capacity information through macOS system APIs. It does not collect telemetry, send analytics, sync data, or transmit drive information over the network.

## License

DriveInspector is open source under the MIT License. You may use, copy, modify, merge, publish, distribute, sublicense, and sell copies of the software, provided the MIT copyright and permission notice are included in copies or substantial portions of the software.

See [LICENSE](LICENSE) for the full terms.
