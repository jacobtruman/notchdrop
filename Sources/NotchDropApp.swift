import SwiftUI
import Cocoa

@main
struct NotchDropApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var controller: HiddenBarController?
    var settingsWindow: NSWindow?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        controller = HiddenBarController(openSettings: { [weak self] in
            self?.showSettings()
        })
        
        NSApp.setActivationPolicy(.accessory)
        
        if !AXIsProcessTrusted() {
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
            AXIsProcessTrustedWithOptions(options)
        }
    }
    
    func showSettings() {
        if let window = settingsWindow {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        guard let controller = controller else { return }
        let settingsView = SettingsView(scanner: controller.scanner)
        let hostingController = NSHostingController(rootView: settingsView)
        
        let window = NSWindow(contentViewController: hostingController)
        window.title = "About NotchDrop"
        window.styleMask = [.titled, .closable]
        window.setContentSize(NSSize(width: 450, height: 300))
        window.center()
        window.makeKeyAndOrderFront(nil)
        window.isReleasedWhenClosed = false
        
        settingsWindow = window
        NSApp.activate(ignoringOtherApps: true)
    }
}
