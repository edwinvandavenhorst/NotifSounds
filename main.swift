import Cocoa
import ServiceManagement

// MARK: - Custom toggle switch

final class ToggleSwitch: NSControl {
    var isOn: Bool = false { didSet { needsDisplay = true } }

    override var intrinsicContentSize: NSSize { NSSize(width: 38, height: 22) }
    override var acceptsFirstResponder: Bool { false }

    override func mouseUp(with event: NSEvent) {
        guard isEnabled else { return }
        isOn.toggle()
        sendAction(action, to: target)
    }

    override func draw(_ dirtyRect: NSRect) {
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }
        let w = bounds.width, h = bounds.height, r = h / 2
        let trackColor: CGColor = isOn
            ? NSColor.controlAccentColor.cgColor
            : CGColor(red: 0.47, green: 0.47, blue: 0.49, alpha: 1)
        let track = CGPath(roundedRect: bounds, cornerWidth: r, cornerHeight: r, transform: nil)
        ctx.addPath(track); ctx.setFillColor(trackColor); ctx.fillPath()
        let pad: CGFloat = 2, d = h - pad * 2
        let tx: CGFloat  = isOn ? w - d - pad : pad
        ctx.saveGState()
        ctx.setShadow(offset: CGSize(width: 0, height: -1), blur: 2,
                      color: CGColor(gray: 0, alpha: 0.3))
        ctx.setFillColor(CGColor(gray: 1, alpha: 1))
        ctx.fillEllipse(in: CGRect(x: tx, y: pad, width: d, height: d))
        ctx.restoreGState()
    }
}

// MARK: - Drop-down content

final class ContentViewController: NSViewController {
    var onToggle: ((Bool) -> Void)?
    var onVolumeChange: ((Int) -> Void)?
    var onStartAtLoginToggle: ((Bool) -> Void)?
    var onHide: (() -> Void)?
    var onAbout: (() -> Void)?

    private var soundsToggle: ToggleSwitch!
    private var volumeSlider: NSSlider!
    private var volumeValueLabel: NSTextField!
    private var loginToggle: ToggleSwitch!

    override func loadView() { view = NSView() }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Row 1 — Notification Sounds + toggle
        soundsToggle = ToggleSwitch()
        soundsToggle.target = self
        soundsToggle.action = #selector(soundsToggleChanged)
        soundsToggle.translatesAutoresizingMaskIntoConstraints = false
        let row1 = hrow([makeLabel("Notification Sounds"), spring(), soundsToggle])

        // Row 2 — Volume slider
        volumeSlider = NSSlider(value: 100, minValue: 0, maxValue: 100,
                                target: self, action: #selector(sliderChanged))
        volumeSlider.controlSize = .small
        volumeSlider.isContinuous = true
        volumeSlider.translatesAutoresizingMaskIntoConstraints = false

        volumeValueLabel = makeLabel("100%", color: .secondaryLabelColor,
                                     size: NSFont.smallSystemFontSize)
        volumeValueLabel.alignment = .right
        volumeValueLabel.translatesAutoresizingMaskIntoConstraints = false
        volumeValueLabel.widthAnchor.constraint(equalToConstant: 34).isActive = true
        let row2 = hrow([makeLabel("Volume", color: .secondaryLabelColor),
                         volumeSlider, volumeValueLabel])

        // Row 3 — Start at Login
        loginToggle = ToggleSwitch()
        loginToggle.target = self
        loginToggle.action = #selector(loginToggleChanged)
        loginToggle.translatesAutoresizingMaskIntoConstraints = false
        let row3 = hrow([makeLabel("Start at Login", color: .secondaryLabelColor),
                         spring(), loginToggle])

        // Separator
        let sep = NSBox()
        sep.boxType = .separator
        sep.translatesAutoresizingMaskIntoConstraints = false

        // Footer — About… · Hide Icon… · Quit
        let footer = hrow([footerBtn("About…",     #selector(aboutTapped)),
                           spring(),
                           footerBtn("Hide Icon…", #selector(hideTapped)),
                           footerBtn("Quit",       #selector(quitTapped))])

        let p: CGFloat = 16
        [row1, row2, row3, sep, footer].forEach { view.addSubview($0) }

        NSLayoutConstraint.activate([
            view.widthAnchor.constraint(equalToConstant: 250),

            row1.topAnchor.constraint(equalTo: view.topAnchor, constant: 14),
            row1.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: p),
            row1.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -p),

            row2.topAnchor.constraint(equalTo: row1.bottomAnchor, constant: 10),
            row2.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: p),
            row2.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -p),

            row3.topAnchor.constraint(equalTo: row2.bottomAnchor, constant: 10),
            row3.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: p),
            row3.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -p),

            sep.topAnchor.constraint(equalTo: row3.bottomAnchor, constant: 10),
            sep.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: p),
            sep.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -p),

            footer.topAnchor.constraint(equalTo: sep.bottomAnchor, constant: 8),
            footer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: p),
            footer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -p),
            footer.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -12),
        ])
    }

    func configure(isOn: Bool, volume: Int, startAtLogin: Bool) {
        soundsToggle.isOn            = isOn
        volumeSlider.integerValue    = volume
        volumeValueLabel.stringValue = "\(volume)%"
        loginToggle.isOn             = startAtLogin
    }

    // MARK: Actions

    @objc private func soundsToggleChanged() {
        let on = soundsToggle.isOn
        if !on { volumeSlider.integerValue = 0; volumeValueLabel.stringValue = "0%" }
        onToggle?(on)
    }

    @objc private func sliderChanged() {
        let v = volumeSlider.integerValue
        volumeValueLabel.stringValue = "\(v)%"
        let on = soundsToggle.isOn
        if v > 0 && !on { soundsToggle.isOn = true  }
        if v == 0 && on { soundsToggle.isOn = false }
        onVolumeChange?(v)
    }

    @objc private func loginToggleChanged() { onStartAtLoginToggle?(loginToggle.isOn) }
    @objc private func aboutTapped() { onAbout?() }
    @objc private func hideTapped()  { onHide?() }
    @objc private func quitTapped()  { NSApp.terminate(nil) }

    // MARK: Layout helpers

    private func makeLabel(_ text: String, color: NSColor = .labelColor,
                            size: CGFloat = NSFont.systemFontSize) -> NSTextField {
        let f = NSTextField(labelWithString: text)
        f.font = .systemFont(ofSize: size); f.textColor = color
        f.translatesAutoresizingMaskIntoConstraints = false
        return f
    }

    private func footerBtn(_ title: String, _ action: Selector) -> NSButton {
        let b = NSButton(title: title, target: self, action: action)
        b.bezelStyle = .inline; b.isBordered = false
        b.font = .systemFont(ofSize: NSFont.smallSystemFontSize)
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }

    private func hrow(_ views: [NSView]) -> NSStackView {
        let s = NSStackView(views: views)
        s.orientation = .horizontal; s.alignment = .centerY; s.spacing = 8
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }

    private func spring() -> NSView {
        let v = NSView(); v.translatesAutoresizingMaskIntoConstraints = false
        v.setContentHuggingPriority(.defaultLow, for: .horizontal)
        v.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return v
    }
}

// MARK: - About window

final class AboutWindowController: NSWindowController, NSWindowDelegate {

    static let shared = AboutWindowController()

    private init() {
        let win = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 280, height: 240),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered, defer: false
        )
        win.title = "NotiSounds"
        win.titlebarAppearsTransparent = true
        win.isMovableByWindowBackground = true
        win.backgroundColor = NSColor(calibratedWhite: 0.11, alpha: 1)
        win.isReleasedWhenClosed = false
        super.init(window: win)
        win.delegate = self
        buildUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    func show() {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        window?.center()
        window?.makeKeyAndOrderFront(nil)
    }

    func windowWillClose(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }

    private func buildUI() {
        guard let cv = window?.contentView else { return }

        // Icon
        let icon = NSImageView()
        icon.image = NSApp.applicationIconImage
        icon.imageScaling = .scaleProportionallyUpOrDown
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.widthAnchor.constraint(equalToConstant: 64).isActive = true
        icon.heightAnchor.constraint(equalToConstant: 64).isActive = true

        // Name
        let nameLabel = fixed("NotiSounds", size: 20, bold: true, color: .white)

        // Version
        let v = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let verLabel = fixed("Version \(v)", size: 12, bold: false,
                             color: NSColor(white: 0.55, alpha: 1))

        // Links
        let rnBtn = link("Release Notes", #selector(openReleaseNotes))
        let ppBtn = link("Privacy Policy", #selector(openPrivacyPolicy))
        let linksRow = NSStackView(views: [rnBtn, ppBtn])
        linksRow.spacing = 16
        linksRow.translatesAutoresizingMaskIntoConstraints = false

        // Copyright
        let year = Calendar.current.component(.year, from: Date())
        let cpLabel = fixed("© \(year) Ed Explore", size: 11, bold: false,
                            color: NSColor(white: 0.38, alpha: 1))

        let stack = NSStackView(views: [icon, nameLabel, verLabel, linksRow, cpLabel])
        stack.orientation = .vertical; stack.alignment = .centerX; stack.spacing = 6
        stack.translatesAutoresizingMaskIntoConstraints = false
        cv.addSubview(stack)

        stack.setCustomSpacing(12, after: icon)
        stack.setCustomSpacing(20, after: verLabel)
        stack.setCustomSpacing(12, after: linksRow)

        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: cv.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: cv.centerYAnchor, constant: 12),
        ])
    }

    private func fixed(_ text: String, size: CGFloat, bold: Bool, color: NSColor) -> NSTextField {
        let f = NSTextField(labelWithString: text)
        f.font = bold ? .boldSystemFont(ofSize: size) : .systemFont(ofSize: size)
        f.textColor = color; f.translatesAutoresizingMaskIntoConstraints = false
        return f
    }

    private func link(_ title: String, _ action: Selector) -> NSButton {
        let b = NSButton(title: "", target: self, action: action)
        b.isBordered = false; b.bezelStyle = .inline
        b.translatesAutoresizingMaskIntoConstraints = false
        b.attributedTitle = NSAttributedString(string: title, attributes: [
            .foregroundColor: NSColor.controlAccentColor,
            .font: NSFont.systemFont(ofSize: 12),
        ])
        return b
    }

    @objc private func openReleaseNotes() {
        NSWorkspace.shared.open(URL(string: "https://edexplore.app/notisounds/release-notes")!)
    }
    @objc private func openPrivacyPolicy() {
        NSWorkspace.shared.open(URL(string: "https://edexplore.app/notisounds/privacy")!)
    }
}

// MARK: - App delegate

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var contentVC: ContentViewController!
    private var dropPanel: NSPanel?
    private var clickMonitor: Any?

    private let backupPath = NSHomeDirectory() + "/.config/notif-volume-backup"
    private let about = AboutWindowController.shared

    func applicationDidFinishLaunching(_: Notification) {
        NSApp.setActivationPolicy(.accessory)
        setupContent()
        setupStatusItem()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in self?.openPanel() }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows: Bool) -> Bool {
        if statusItem == nil { setupStatusItem() }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in self?.openPanel() }
        return true
    }

    // MARK: Setup

    private func setupContent() {
        contentVC = ContentViewController()
        contentVC.onToggle             = { [weak self] on in self?.handleToggle(on) }
        contentVC.onVolumeChange       = { [weak self] v  in self?.handleVolumeChange(v) }
        contentVC.onStartAtLoginToggle = { [weak self] on in self?.handleLoginItem(on) }
        contentVC.onHide               = { [weak self] in self?.closePanel(); self?.showHideDialog() }
        contentVC.onAbout              = { [weak self] in self?.closePanel(); self?.about.show() }
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem?.button?.action = #selector(buttonClicked)
        statusItem?.button?.target = self
        refreshIcon()
    }

    // MARK: Drop panel

    private func makeDropPanel() -> NSPanel {
        let blur = NSVisualEffectView()
        blur.material = .popover; blur.blendingMode = .behindWindow; blur.state = .active
        blur.wantsLayer = true
        blur.layer?.cornerRadius = 10; blur.layer?.masksToBounds = true

        let inner = contentVC.view
        inner.translatesAutoresizingMaskIntoConstraints = false
        blur.addSubview(inner)
        NSLayoutConstraint.activate([
            inner.topAnchor.constraint(equalTo: blur.topAnchor),
            inner.leadingAnchor.constraint(equalTo: blur.leadingAnchor),
            inner.trailingAnchor.constraint(equalTo: blur.trailingAnchor),
            inner.bottomAnchor.constraint(equalTo: blur.bottomAnchor),
        ])
        blur.layoutSubtreeIfNeeded()
        var sz = inner.fittingSize
        if sz.height < 20 { sz = NSSize(width: 250, height: 160) }

        let panel = NSPanel(contentRect: NSRect(origin: .zero, size: sz),
                            styleMask: [.borderless, .nonactivatingPanel],
                            backing: .buffered, defer: false)
        panel.contentView = blur; panel.isOpaque = false
        panel.backgroundColor = NSColor.clear; panel.hasShadow = true
        panel.level = NSWindow.Level.popUpMenu; panel.isReleasedWhenClosed = false
        panel.collectionBehavior = NSWindow.CollectionBehavior([.canJoinAllSpaces, .fullScreenAuxiliary])
        panel.appearance = NSApp.effectiveAppearance
        return panel
    }

    @objc private func buttonClicked() {
        if let panel = dropPanel, panel.isVisible { closePanel() } else { openPanel() }
    }

    private func openPanel() {
        guard let button = statusItem?.button else { return }
        if dropPanel == nil { dropPanel = makeDropPanel() }
        let panel = dropPanel!

        let vol     = alertVolume()
        let isOn    = vol > 0
        let loginOn = SMAppService.mainApp.status == .enabled
        contentVC.configure(isOn: isOn, volume: isOn ? vol : 0, startAtLogin: loginOn)

        guard let btnWin = button.window else { return }
        let btnScreen = btnWin.convertToScreen(button.convert(button.bounds, to: nil))
        var origin = NSPoint(x: btnScreen.midX - panel.frame.width / 2,
                             y: btnScreen.minY - panel.frame.height - 4)
        if let screen = NSScreen.main {
            let vf = screen.visibleFrame
            origin.x = max(vf.minX + 4, min(origin.x, vf.maxX - panel.frame.width - 4))
        }
        panel.setFrameOrigin(origin)
        panel.orderFront(nil)

        clickMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown]
        ) { [weak self] _ in
            guard let self else { return }
            if let p = self.dropPanel, p.frame.contains(NSEvent.mouseLocation) { return }
            self.closePanel()
        }
    }

    private func closePanel() { dropPanel?.close(); removeClickMonitor() }
    private func removeClickMonitor() {
        if let m = clickMonitor { NSEvent.removeMonitor(m); clickMonitor = nil }
    }

    // MARK: Handlers

    private func handleToggle(_ on: Bool) {
        if on {
            let vol = savedVolume()
            setAlertVolume(vol)
            contentVC.configure(isOn: true, volume: vol,
                                startAtLogin: SMAppService.mainApp.status == .enabled)
        } else {
            let cur = alertVolume()
            if cur > 0 { try? "\(cur)".write(toFile: backupPath, atomically: true, encoding: .utf8) }
            setAlertVolume(0)
            contentVC.configure(isOn: false, volume: 0,
                                startAtLogin: SMAppService.mainApp.status == .enabled)
        }
        refreshIcon()
    }

    private func handleVolumeChange(_ volume: Int) {
        if volume > 0 {
            try? "\(volume)".write(toFile: backupPath, atomically: true, encoding: .utf8)
        }
        setAlertVolume(volume)
        refreshIcon()
    }

    private func handleLoginItem(_ on: Bool) {
        do {
            if on { try SMAppService.mainApp.register() }
            else  { try SMAppService.mainApp.unregister() }
        } catch {
            // Registration failed (app may not be in /Applications) — revert the UI
            let vol = alertVolume()
            contentVC.configure(isOn: vol > 0, volume: vol > 0 ? vol : 0,
                                startAtLogin: SMAppService.mainApp.status == .enabled)
        }
    }

    // MARK: Hide dialog

    private func showHideDialog() {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)

        let alert = NSAlert()
        alert.messageText     = "Hide Menu Bar Icon"
        alert.informativeText = "What should happen while the icon is hidden?\n\nTo show the icon again, reopen the app from Applications."
        alert.alertStyle      = .informational
        alert.addButton(withTitle: "Run in Background")
        alert.addButton(withTitle: "Close App")
        alert.addButton(withTitle: "Cancel")

        switch alert.runModal() {
        case .alertFirstButtonReturn:
            if let item = statusItem { NSStatusBar.system.removeStatusItem(item) }
            statusItem = nil
            NSApp.setActivationPolicy(.accessory)
        case .alertSecondButtonReturn:
            restoreSounds(); NSApp.terminate(nil)
        default:
            NSApp.setActivationPolicy(.accessory)
        }
    }

    // MARK: Helpers

    private func refreshIcon() {
        let on  = alertVolume() > 0
        let img = NSImage(systemSymbolName: on ? "bell.fill" : "bell.slash.fill",
                          accessibilityDescription: nil)
        img?.isTemplate = true
        statusItem?.button?.image = img
    }

    private func restoreSounds() {
        guard alertVolume() == 0 else { return }
        setAlertVolume(savedVolume())
    }

    private func savedVolume() -> Int {
        (try? String(contentsOfFile: backupPath, encoding: .utf8))
            .flatMap { Int($0.trimmingCharacters(in: .whitespacesAndNewlines)) } ?? 100
    }

    private func alertVolume() -> Int {
        let src = "set s to (get volume settings)\nreturn alert volume of s"
        guard let script = NSAppleScript(source: src) else { return 100 }
        var err: NSDictionary?
        let result = script.executeAndReturnError(&err)
        return err == nil ? Int(result.int32Value) : 100
    }

    private func setAlertVolume(_ v: Int) {
        guard let script = NSAppleScript(source: "set volume alert volume \(v)") else { return }
        var err: NSDictionary?
        script.executeAndReturnError(&err)
    }
}

// MARK: - Entry point
// Global strong reference — NSApplication.delegate is weak so a local would be released by ARC.
let appDelegate = AppDelegate()
let app = NSApplication.shared
app.delegate = appDelegate
app.run()
