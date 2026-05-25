# NotifSounds

A lightweight macOS menu bar app that controls notification alert sounds independently from the system output volume. Built entirely in Swift using `swiftc` — no Xcode project required to build or run locally.

![NotifSounds menu bar dropdown](icons/amber_preview.png)

---

## What it does

- **Toggle** notification sounds on/off (blue = on, grey = off)
- **Volume slider** (0–100 %) adjusts alert volume without touching speaker volume
- Dragging the slider to 0 % automatically mutes; dragging above 0 % automatically unmutes
- **Start at Login** — registers/removes itself as a macOS login item
- **About** panel with links to Release Notes and Privacy Policy
- Lives entirely in the menu bar — no Dock icon, no windows

---

## Requirements

| | |
|---|---|
| macOS | 13 Ventura or later |
| Build tools | Xcode Command Line Tools (`xcode-select --install`) |
| Runtime | No dependencies — pure AppKit + ServiceManagement |

---

## Build & install locally

```bash
chmod +x build.sh
./build.sh
```

The script compiles `main.swift`, ad-hoc signs the `.app` bundle, and offers to install it to `/Applications`. No Apple Developer account needed for local use.

To regenerate the app icon from source:

```bash
swift make_icns.swift      # writes icons/AppIcon.icns + full iconset
```

---

## File structure

```
main.swift                  All Swift source — ToggleSwitch, ContentViewController,
                            AboutWindowController, AppDelegate
Info.plist                  Bundle metadata (LSUIElement, CFBundleIconFile, etc.)
NotifSounds.entitlements    Sandbox + permissions (sandbox OFF for local dev)
build.sh                    Compile → sign (ad-hoc) → install to /Applications
generate_icons.swift        Generates the three initial icon design options
make_icns.swift             Renders all required icon sizes and packages AppIcon.icns
icons/
  AppIcon.icns              Bundled app icon (amber gradient, white bell)
  AppIcon.iconset/          Source PNGs at every required macOS size
  amber_preview.png         512 px preview of the chosen icon
```

---

## Architecture & key decisions

### NSPanel instead of NSPopover

`NSPopover` silently fails to render when shown from a `.nonactivatingPanel` status-item app on macOS 14+. The dropdown is instead an `NSPanel` with:

- `styleMask: [.borderless, .nonactivatingPanel]` — no title bar, does not steal focus
- `NSVisualEffectView(.popover)` background — native frosted-glass material
- `level = .popUpMenu` — floats above regular windows
- Manual positioning below the status button using `convertToScreen`
- A global `NSEvent` monitor for outside-click dismissal

The monitor is added *after* the opening click to avoid immediately self-closing.

### Global delegate reference (critical ARC fix)

`NSApplication.delegate` is a **weak** reference. Declaring the delegate as a local variable (`let delegate = AppDelegate()`) allows ARC to release it before any events fire, silently breaking all button actions. The fix is a file-scope global:

```swift
let appDelegate = AppDelegate()   // strong — lives for the process lifetime
app.delegate = appDelegate
app.run()
```

### Custom ToggleSwitch instead of NSSwitch

`NSSwitch` does not inherit the correct dark/light appearance when hosted inside a `.nonactivatingPanel` — it renders without accent colour regardless of `panel.appearance` settings. A custom 38 × 22 pt `NSControl` drawn with CoreGraphics resolves this completely:

- ON state → `NSColor.controlAccentColor` (respects the user's chosen accent colour)
- OFF state → neutral grey
- Works correctly in any window context with no appearance configuration

### NSAppleScript instead of a subprocess

Alert volume was originally set via `Process` + `osascript`. Replaced with `NSAppleScript`:

- No subprocess spawn overhead
- **Sandbox-compatible**: works in a sandboxed Mac App Store build with the `com.apple.security.automation.apple-events` entitlement targeting `com.apple.systemevents`

### CoreAudio research note

`kAudioHardwarePropertyAlertVolume` is **not present** in the current public CoreAudio SDK headers on macOS 26. Alert volume control therefore remains via AppleScript, which is the only documented public API path for this property.

### SMAppService for login item

Uses `SMAppService.mainApp.register() / .unregister()` (macOS 13+) rather than the deprecated `SMLoginItemSetEnabled` or `LSSharedFileList` APIs. No entitlement is required; the app simply needs to be installed in `/Applications`.

---

## App Store readiness checklist

The Swift source, icon, and `Info.plist` are already App Store-ready. Three file changes are needed at submission time:

**`NotifSounds.entitlements`**

```diff
- <key>com.apple.security.app-sandbox</key><false/>
+ <key>com.apple.security.app-sandbox</key><true/>

+ <key>com.apple.security.automation.apple-events</key>
+ <dict><key>com.apple.systemevents</key><true/></dict>
```

**`Info.plist`** — add one key:

```xml
<key>NSAppleEventsUsageDescription</key>
<string>NotifSounds uses AppleScript to read and set the system alert volume.</string>
```

**Then:**

- [ ] Enroll in Apple Developer Program (€99 / year)
- [ ] Create Xcode project, import all source files, assign Distribution certificate
- [ ] Host Privacy Policy at `edexplore.app/notifsounds/privacy`
- [ ] Host Release Notes at `edexplore.app/notifsounds/release-notes`
- [ ] Set price to Tier 1 (€0.99) in App Store Connect
- [ ] Submit for review

---

## Icon

The amber gradient icon was generated programmatically via `make_icns.swift` using `NSBitmapImageRep` + `NSGradient` + SF Symbols, producing all ten required macOS icon sizes (16 px → 1024 px @2x) without Xcode or external tools.

---

## License

© 2026 Edwin van Davenhorst. All rights reserved.
