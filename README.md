# DriveInspector

DriveInspector is a native macOS menu bar app that monitors mounted drives and gives a quick view of disk availability.

## Highlights

- Menu bar badge showing **free percentage for the startup/internal default drive (`/`)**
- Live disk list with internal and external volumes
- Per-disk capacity cards with a usage bar and Finder shortcut
- Lightweight native AppKit UI

## Latest Improvements (v1.0.0)

- Fixed status badge logic to use the startup drive instead of a generic internal disk
- Switched badge semantics to show **free %** (not used %)
- Added safer capacity math (clamped values) to avoid invalid percentage edge cases
- Improved disk change detection for more reliable UI refreshes
- Cleaned app icon asset set with correctly sized icon files for macOS slots

## Build

### Requirements

- macOS 13.0+
- Xcode 15+

### Local Build

```bash
xcodebuild -project DriveInspector.xcodeproj -scheme DriveInspector -configuration Release build
```

## Project

- Language: Swift
- UI: AppKit
- Entry point: `DriveInspector/main.swift`

## License

Private - All rights reserved.
