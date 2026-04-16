# NotchDrop

A macOS menu bar app that gives you access to menu bar items hidden behind the MacBook notch.

## The Problem

On MacBook Pro models with a notch, menu bar items can get pushed behind the camera notch and become completely inaccessible - you can't see them or click them.

## The Solution

NotchDrop sits in your menu bar and detects items that are hidden behind the notch. Click the NotchDrop icon to see a dropdown list of all hidden items, then click any item to activate it.

## Features

- **Detects hidden items** - Uses macOS Accessibility APIs to find menu bar items behind the notch
- **One-click access** - Click any hidden item in the dropdown to activate it
- **Adjustable notch width** - Configure the detection zone in settings
- **Lightweight** - Runs as a menu bar app with minimal resources

## Requirements

- macOS 13.0 (Ventura) or later
- **Accessibility permission** - Required to detect and interact with other apps' menu bar items

## Building

Requires Swift 5.9+ and macOS 13.0 (Ventura) or later.

```bash
# Build a release binary and create the app bundle
./build-app.sh
```

This compiles the project, creates `NotchDrop.app`, and prints next steps.

To build without creating the app bundle:

```bash
swift build            # debug
swift build -c release # release
```

## Installing

Copy the app bundle to `/Applications`:

```bash
cp -r NotchDrop.app /Applications/
```

Or run it directly from the project directory:

```bash
open NotchDrop.app
```

## Usage

1. Launch the app — it appears as a menu bar icon
2. **Grant accessibility permission** when prompted (required for the app to work)
3. **Left-click** the icon to see hidden menu bar items
4. **Right-click** for options and quit
5. Click any item in the dropdown to activate it
6. **Keyboard shortcut:** ⌃⌥⌘N to open the hidden items menu

## How It Works

The app uses macOS Accessibility APIs to:
1. Enumerate all running applications
2. Find their menu bar "extras" (status items)
3. Get the position of each item
4. Determine which items fall within the notch zone
5. Provide a way to click/activate those hidden items

## Permissions

This app requires **Accessibility** permission to function. When you first run it:
1. You'll be prompted to grant access
2. Go to System Settings → Privacy & Security → Accessibility
3. Enable NotchDrop in the list

Without this permission, the app cannot detect or interact with other apps' menu bar items.

## License

MIT License
