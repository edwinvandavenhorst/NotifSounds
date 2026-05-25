# CLAUDE.md — NotifSounds

## Working directory
All source editing, building, and testing happens from:
```
~/Documents/Claude/NotifSoundsApp/
```

## Build & install
```bash
cd ~/Documents/Claude/NotifSoundsApp

# Compile, sign (ad-hoc), install to /Applications, relaunch
swiftc -framework Cocoa -O main.swift \
  -o build/NotifSounds.app/Contents/MacOS/NotifSounds
codesign --force --sign - build/NotifSounds.app
pkill -x NotifSounds 2>/dev/null || true
sleep 0.3
rm -rf /Applications/NotifSounds.app
cp -r build/NotifSounds.app /Applications/
open /Applications/NotifSounds.app
```

**Important:** always `rm -rf /Applications/NotifSounds.app` before `cp -r`.
`cp -r src /Applications/ExistingApp.app` nests the bundle instead of replacing it.

## Version control workflow
GitHub is the version tracker: **github.com/edwinvandavenhorst/NotifSounds**

After every meaningful change:
```bash
cd ~/Documents/Claude/NotifSoundsApp
git add -p          # or git add <specific files>
git commit -m "..."
git push
```

## App structure
All Swift source lives in a single file: `main.swift`
- `ToggleSwitch`          — custom CoreGraphics toggle (replaces NSSwitch)
- `ContentViewController` — dropdown panel UI
- `AboutWindowController` — About window
- `AppDelegate`           — status item, panel, audio, login item

## Key commands
```bash
notif-sounds status   # check alert volume from terminal
notif-sounds off      # mute notifications
notif-sounds on       # restore
```

## Regenerate icon
```bash
swift make_icns.swift   # rewrites icons/AppIcon.icns + iconset
# then rebuild the app to bundle the new icon
```
