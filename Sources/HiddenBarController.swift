import AppKit
import Carbon

class HiddenBarController: NSObject {
    private var statusItem: NSStatusItem!
    let scanner: MenuBarScanner
    private var hotKeyRef: EventHotKeyRef?
    private var openSettings: () -> Void

    init(openSettings: @escaping () -> Void) {
        self.scanner = MenuBarScanner()
        self.openSettings = openSettings
        super.init()

        setupStatusItem()
        setupGlobalHotKey()
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem.button {
            let image = NSImage(systemSymbolName: "menubar.arrow.down.rectangle", accessibilityDescription: "NotchDrop")
            image?.isTemplate = true
            button.image = image
            button.action = #selector(statusItemClicked(_:))
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            button.toolTip = "NotchDrop (⌃⌥⌘N)"
        }
    }

    private func setupGlobalHotKey() {
        var hotKeyID = EventHotKeyID()
        hotKeyID.signature = OSType(0x4E444850)
        hotKeyID.id = 1

        let modifiers: UInt32 = UInt32(controlKey | optionKey | cmdKey)
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))

        let handler: EventHandlerUPP = { (_, _, userData) -> OSStatus in
            let controller = Unmanaged<HiddenBarController>.fromOpaque(userData!).takeUnretainedValue()
            DispatchQueue.main.async { controller.showHiddenItems() }
            return noErr
        }

        var eventHandler: EventHandlerRef?
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()
        InstallEventHandler(GetApplicationEventTarget(), handler, 1, &eventType, selfPtr, &eventHandler)
        RegisterEventHotKey(UInt32(kVK_ANSI_N), modifiers, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)
    }

    @objc private func statusItemClicked(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }

        if event.type == .rightMouseUp {
            showContextMenu()
        } else {
            showHiddenItems()
        }
    }

    func showHiddenItems() {
        if scanner.allItems.isEmpty {
            scanner.scan()
        }

        let hidden = scanner.hiddenItems
        let notch = scanner.notchInfo

        let menu = NSMenu()

        if !AXIsProcessTrusted() {
            menu.addItem(headerItem("Accessibility permission required"))
        } else if notch?.exists != true {
            menu.addItem(headerItem("No notch detected"))
        } else if hidden.isEmpty {
            menu.addItem(headerItem("No items behind the notch"))
        } else {
            for item in hidden {
                let mi = NSMenuItem(title: item.displayName, action: #selector(clickItem(_:)), keyEquivalent: "")
                mi.target = self
                mi.representedObject = item
                if let icon = item.appIcon {
                    mi.image = icon
                }
                menu.addItem(mi)
            }
        }

        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    private func showContextMenu() {
        let menu = NSMenu()

        let hotkeyItem = headerItem("Hotkey: ⌃⌥⌘N")
        menu.addItem(hotkeyItem)

        menu.addItem(NSMenuItem.separator())

        let settingsItem = NSMenuItem(title: "About NotchDrop", action: #selector(settingsClicked), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

        let quitItem = NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quitItem)

        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    private func headerItem(_ title: String) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.isEnabled = false
        return item
    }

    @objc private func settingsClicked() {
        openSettings()
    }

    @objc private func clickItem(_ sender: NSMenuItem) {
        guard let item = sender.representedObject as? DetectedMenuBarItem else { return }
        scanner.clickItem(item)
    }

    deinit {
        if let hotKeyRef = hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
        }
    }
}
