import AppKit
import CoreGraphics

struct NotchInfo {
    let exists: Bool
    let rightSafeWidth: CGFloat
    let laptopScreenWidth: CGFloat
}

struct DetectedMenuBarItem {
    let ownerName: String
    let ownerPID: pid_t
    let frame: CGRect
    let displayName: String
    let axElement: AXUIElement
    let appIcon: NSImage?
}

class MenuBarScanner: ObservableObject {
    @Published var allItems: [DetectedMenuBarItem] = []
    @Published var hiddenItems: [DetectedMenuBarItem] = []
    @Published var notchInfo: NotchInfo?

    private var refreshTimer: Timer?

    init() {
        scanInBackground()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            self?.scanInBackground()
        }
    }

    deinit { refreshTimer?.invalidate() }

    func scanInBackground() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            let notch = self.detectNotch()
            let items = self.collectAllExtras()
            let hidden = self.computeHidden(items: items, notch: notch)

            DispatchQueue.main.async {
                self.notchInfo = notch
                self.allItems = items
                self.hiddenItems = hidden
            }
        }
    }

    func scan() {
        let notch = detectNotch()
        let items = collectAllExtras()
        let hidden = computeHidden(items: items, notch: notch)

        self.notchInfo = notch
        self.allItems = items
        self.hiddenItems = hidden
    }

    private func computeHidden(items: [DetectedMenuBarItem], notch: NotchInfo) -> [DetectedMenuBarItem] {
        guard notch.exists, !items.isEmpty else { return [] }

        // Find the rightmost edge of all items - this is the right edge of the menu bar
        let rightmostEdge = items.map { $0.frame.maxX }.max() ?? 0
        guard rightmostEdge > 0 else { return [] }

        // The right safe zone extends leftward from the rightmost edge.
        // Anything to the left of that cutoff is behind or past the notch.
        let safeCutoff = rightmostEdge - notch.rightSafeWidth

        return items.filter { $0.frame.midX < safeCutoff }
    }

    private func detectNotch() -> NotchInfo {
        guard #available(macOS 12.0, *) else {
            return NotchInfo(exists: false, rightSafeWidth: 0, laptopScreenWidth: 0)
        }

        for screen in NSScreen.screens {
            if screen.safeAreaInsets.top != 0 {
                let rightArea = screen.auxiliaryTopRightArea ?? .zero
                return NotchInfo(
                    exists: true,
                    rightSafeWidth: rightArea.width,
                    laptopScreenWidth: screen.frame.width
                )
            }
        }

        return NotchInfo(exists: false, rightSafeWidth: 0, laptopScreenWidth: 0)
    }

    private func collectAllExtras() -> [DetectedMenuBarItem] {
        guard AXIsProcessTrusted() else { return [] }

        var items: [DetectedMenuBarItem] = []
        let myPID = ProcessInfo.processInfo.processIdentifier

        for app in NSWorkspace.shared.runningApplications {
            let pid = app.processIdentifier
            if pid == myPID { continue }

            let appElement = AXUIElementCreateApplication(pid)

            var barRef: CFTypeRef?
            guard AXUIElementCopyAttributeValue(
                appElement, kAXExtrasMenuBarAttribute as CFString, &barRef
            ) == .success else { continue }

            var childrenRef: CFTypeRef?
            guard AXUIElementCopyAttributeValue(
                barRef as! AXUIElement, kAXChildrenAttribute as CFString, &childrenRef
            ) == .success, let children = childrenRef as? [AXUIElement] else { continue }

            let appName = app.localizedName ?? app.bundleIdentifier ?? "Unknown"

            for child in children {
                var pos = CGPoint.zero
                var size = CGSize.zero

                var posRef: CFTypeRef?
                var sizeRef: CFTypeRef?
                if AXUIElementCopyAttributeValue(child, kAXPositionAttribute as CFString, &posRef) == .success {
                    AXValueGetValue(posRef as! AXValue, .cgPoint, &pos)
                }
                if AXUIElementCopyAttributeValue(child, kAXSizeAttribute as CFString, &sizeRef) == .success {
                    AXValueGetValue(sizeRef as! AXValue, .cgSize, &size)
                }

                guard pos.x > 0, size.width > 0, size.height > 0 else { continue }

                let label = axLabel(for: child)
                let displayName: String
                if !label.isEmpty && (appName == "Control Center" || appName == "SystemUIServer") {
                    displayName = label
                } else if !label.isEmpty {
                    displayName = "\(appName) — \(label)"
                } else {
                    displayName = appName
                }

                let appIcon: NSImage?
                if appName == "Control Center" || appName == "SystemUIServer" {
                    appIcon = systemItemIcon(for: label)
                } else if let icon = app.icon {
                    icon.size = NSSize(width: 16, height: 16)
                    appIcon = icon
                } else {
                    appIcon = nil
                }

                items.append(DetectedMenuBarItem(
                    ownerName: appName,
                    ownerPID: pid,
                    frame: CGRect(origin: pos, size: size),
                    displayName: displayName,
                    axElement: child,
                    appIcon: appIcon
                ))
            }
        }

        items.sort { $0.frame.minX < $1.frame.minX }
        return items
    }

    private func systemItemIcon(for label: String) -> NSImage? {
        let lowered = label.lowercased()

        let symbolName: String
        if lowered.contains("wi-fi") || lowered.contains("wi\u{2011}fi") {
            symbolName = "wifi"
        } else if lowered.contains("bluetooth") {
            symbolName = "wave.3.right"
        } else if lowered.contains("battery") {
            symbolName = "battery.100"
        } else if lowered.contains("sound") || lowered.contains("volume") {
            symbolName = "speaker.wave.2.fill"
        } else if lowered.contains("clock") || lowered.contains("date") || lowered.contains("time") {
            symbolName = "clock"
        } else if lowered.contains("control center") || lowered.contains("control centre") {
            symbolName = "switch.2"
        } else if lowered.contains("screen mirroring") || lowered.contains("airplay") {
            symbolName = "rectangle.on.rectangle"
        } else if lowered.contains("now playing") || lowered.contains("music") {
            symbolName = "play.fill"
        } else if lowered.contains("focus") || lowered.contains("do not disturb") {
            symbolName = "moon.fill"
        } else if lowered.contains("spotlight") || lowered.contains("search") {
            symbolName = "magnifyingglass"
        } else if lowered.contains("siri") {
            symbolName = "mic.fill"
        } else if lowered.contains("vpn") {
            symbolName = "lock.shield"
        } else if lowered.contains("keyboard") {
            symbolName = "keyboard"
        } else if lowered.contains("accessibility") {
            symbolName = "accessibility"
        } else {
            symbolName = "ellipsis.circle"
        }

        let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: label)
        image?.isTemplate = true
        image?.size = NSSize(width: 16, height: 16)
        return image
    }

    private func axLabel(for element: AXUIElement) -> String {
        for attr in [kAXDescriptionAttribute, kAXTitleAttribute, kAXHelpAttribute, kAXValueAttribute] {
            var ref: CFTypeRef?
            if AXUIElementCopyAttributeValue(element, attr as CFString, &ref) == .success,
               let str = ref as? String, !str.isEmpty {
                return str
            }
        }
        return ""
    }

    func clickItem(_ item: DetectedMenuBarItem) {
        AXUIElementPerformAction(item.axElement, kAXPressAction as CFString)
    }
}
