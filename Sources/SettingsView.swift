import SwiftUI

struct SettingsView: View {
    @ObservedObject var scanner: MenuBarScanner
    
    private var hasAccessibility: Bool {
        AXIsProcessTrusted()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("NotchDrop")
                .font(.title)
                .fontWeight(.semibold)
            
            Text("Access menu bar items hidden behind the notch")
                .foregroundColor(.secondary)
            
            Divider()
            
            GroupBox("Accessibility") {
                HStack {
                    if hasAccessibility {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Permission granted")
                    } else {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("Permission required")
                        Spacer()
                        Button("Grant Access") {
                            let opts = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
                            AXIsProcessTrustedWithOptions(opts)
                        }
                    }
                    Spacer()
                }
                .padding(.vertical, 6)
            }
            
            GroupBox("Display") {
                VStack(alignment: .leading, spacing: 8) {
                    if let notch = scanner.notchInfo, notch.exists {
                        HStack {
                            Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                            Text("Notch detected")
                            Spacer()
                            Text("Right safe: \(Int(notch.rightSafeWidth))px")
                                .foregroundColor(.secondary)
                        }
                    } else {
                        HStack {
                            Image(systemName: "display").foregroundColor(.secondary)
                            Text("No notch detected")
                        }
                    }
                    
                    HStack {
                        Text("Menu bar items: \(scanner.allItems.count)")
                        Spacer()
                        Text("Hidden: \(scanner.hiddenItems.count)")
                            .foregroundColor(scanner.hiddenItems.isEmpty ? .secondary : .orange)
                    }
                    
                    Button("Rescan") { scanner.scan() }
                }
                .padding(.vertical, 6)
            }
            
            GroupBox("Usage") {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Click the menu bar icon to see hidden items")
                    Text("Keyboard shortcut: ⌃⌥⌘N")
                        .font(.caption).foregroundColor(.secondary)
                }
                .padding(.vertical, 6)
            }
            
            Spacer()
            
            HStack {
                Button("Quit") { NSApplication.shared.terminate(nil) }
                Spacer()
            }
        }
        .padding(20)
        .frame(width: 400, height: 300)
        .onAppear { scanner.scan() }
    }
}
