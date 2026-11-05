//
//  HUDController.swift
//  by Danny Stewart (2025)
//  MIT License
//  https://github.com/dannystewart/volumeHUD
//

import AppKit
import Combine
import CoreGraphics
import Foundation
import SwiftUI

@MainActor
class HUDController: ObservableObject {
    @Published var isShowing = false

    let logger: Logger = .init()

    private var hudWindow: NSWindow?
    private var stationarySpaceAttached = false
    private var hostingView: NSHostingView<HUDView>?
    private var hideTimer: Timer?
    private var displayGeneration = 0
    private var lastShownVolume: Float?
    private var lastShownMuted: Bool?
    private var lastShownBrightness: Float?
    private var lastShownHUDType: HUDType?
    private var isObservingDisplayChanges = false
    private let isPreviewMode: Bool
    var isInterceptionActive = false

    init(isPreviewMode: Bool = false) {
        self.isPreviewMode = isPreviewMode
    }

    deinit {}

    @MainActor
    func showVolumeHUD(volume: Float, isMuted: Bool, resetsTimer: Bool = true) {
        displayHUD(hudType: .volume, value: volume, isMuted: isMuted, resetsTimer: resetsTimer)
    }

    #if !SANDBOX
        @MainActor
        func showBrightnessHUD(brightness: Float, resetsTimer: Bool = true) {
            // Only show brightness HUD if the feature is enabled
            guard UserDefaults.standard.bool(forKey: "brightnessEnabled") else {
                logger.debug("Brightness HUD disabled; skipping display.")
                return
            }
            displayHUD(hudType: .brightness, value: brightness, isMuted: false, resetsTimer: resetsTimer)
        }
    #endif // !SANDBOX

    @MainActor
    func startDisplayChangeMonitoring() {
        guard !isObservingDisplayChanges else { return }

        // Skip display monitoring in preview mode
        if isPreviewMode {
            logger.debug("Skipping display monitoring in preview mode.")
            isObservingDisplayChanges = true
            return
        }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(displayConfigurationDidChange(_:)),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil,
        )
        isObservingDisplayChanges = true

        logger.debug("Started monitoring display configuration changes.")
    }

    @MainActor
    func stopDisplayChangeMonitoring() {
        guard isObservingDisplayChanges else { return }
        NotificationCenter.default.removeObserver(
            self,
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil,
        )
        isObservingDisplayChanges = false

        logger.debug("Stopped monitoring display configuration changes.")
    }

    @objc
    private func displayConfigurationDidChange(_: Notification) {
        // Ensure we hop to the main actor for UI work
        Task { @MainActor in
            self.handleDisplayConfigurationChange()
        }
    }

    @MainActor
    private func handleDisplayConfigurationChange() {
        logger.debug("Display configuration changed, updating HUD position.")

        // If the HUD window exists, update its position
        if hudWindow != nil {
            updateWindowPosition()
            // Re-apply after a short delay to handle transient frame/layout updates macOS screen
            // geometry may still be adjusting after didChangeScreenParameters fires
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
                self?.updateWindowPosition()
            }
        }
    }

    @MainActor
    private func updateWindowPosition(for hudType: HUDType? = nil) {
        guard let window = hudWindow else { return }

        let windowSize = NSSize(width: 200, height: 200)

        // Brightness HUD always shows on built-in display (since that's what it controls). Volume
        // HUD respects user preference for display location.
        let targetScreen: NSScreen
        let selectionReason: String
        #if !SANDBOX
            if hudType == .brightness {
                if let builtin = getBuiltinScreen() {
                    targetScreen = builtin
                    selectionReason = "brightness builtin"
                } else if let main = NSScreen.main {
                    targetScreen = main
                    selectionReason = "brightness builtin-missing fallback NSScreen.main"
                } else {
                    targetScreen = NSScreen.screens.first!
                    selectionReason = "brightness builtin-missing fallback firstScreen"
                }
            } else {
                // Check user preference for volume HUD location
                let followMouse = UserDefaults.standard.bool(forKey: "volumeHUDFollowsMouse")
                if followMouse {
                    if let mouse = getScreenWithMouse() {
                        targetScreen = mouse
                        selectionReason = "volume followsMouse"
                    } else if let main = NSScreen.main {
                        targetScreen = main
                        selectionReason = "volume followsMouse missing-mouse fallback NSScreen.main"
                    } else {
                        targetScreen = NSScreen.screens.first!
                        selectionReason = "volume followsMouse missing-mouse fallback firstScreen"
                    }
                } else {
                    if let primary = getPrimaryScreen() {
                        targetScreen = primary
                        selectionReason = "volume primaryDisplay"
                    } else if let main = NSScreen.main {
                        targetScreen = main
                        selectionReason = "volume primaryDisplay missing-primary fallback NSScreen.main"
                    } else {
                        targetScreen = NSScreen.screens.first!
                        selectionReason = "volume primaryDisplay missing-primary fallback firstScreen"
                    }
                }
            }
        #else
            // Check user preference for volume HUD location
            let followMouse = UserDefaults.standard.bool(forKey: "volumeHUDFollowsMouse")
            if followMouse {
                if let mouse = getScreenWithMouse() {
                    targetScreen = mouse
                    selectionReason = "volume followsMouse"
                } else if let main = NSScreen.main {
                    targetScreen = main
                    selectionReason = "volume followsMouse missing-mouse fallback NSScreen.main"
                } else {
                    targetScreen = NSScreen.screens.first!
                    selectionReason = "volume followsMouse missing-mouse fallback firstScreen"
                }
            } else {
                if let primary = getPrimaryScreen() {
                    targetScreen = primary
                    selectionReason = "volume primaryDisplay"
                } else if let main = NSScreen.main {
                    targetScreen = main
                    selectionReason = "volume primaryDisplay missing-primary fallback NSScreen.main"
                } else {
                    targetScreen = NSScreen.screens.first!
                    selectionReason = "volume primaryDisplay missing-primary fallback firstScreen"
                }
            }
        #endif // !SANDBOX

        let selectedDisplayID: CGDirectDisplayID? = {
            guard
                let screenNumber = targetScreen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber else { return nil }
            return CGDirectDisplayID(screenNumber.uint32Value)
        }()
        let selectedDisplayIDText = selectedDisplayID.map { String($0) } ?? "unknown"
        logger.debug("HUD screen selection: \(selectionReason), displayID=\(selectedDisplayIDText), frame=\(targetScreen.frame)")

        // Use full screen frame to ignore Dock positioning
        let screenFrame = targetScreen.frame

        let newWindowRect = NSRect(
            x: screenFrame.origin.x + (screenFrame.width - windowSize.width) / 2,
            y: screenFrame.origin.y + 140,
            width: windowSize.width,
            height: windowSize.height,
        )

        // Update the window frame
        window.setFrame(newWindowRect, display: true)

        logger.debug("Updated HUD window position to: \(newWindowRect)")
    }

    /// Returns the NSScreen that currently contains the mouse cursor
    private func getScreenWithMouse() -> NSScreen? {
        let mouseLocation = NSEvent.mouseLocation

        for screen in NSScreen.screens where screen.frame.contains(mouseLocation) {
            return screen
        }

        return nil
    }

    /// Returns the NSScreen corresponding to the built-in display, if present
    private func getBuiltinScreen() -> NSScreen? {
        for screen in NSScreen.screens {
            if let screenNumber = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber {
                let displayID = CGDirectDisplayID(screenNumber.uint32Value)
                if CGDisplayIsBuiltin(displayID) != 0 {
                    return screen
                }
            }
        }
        return nil
    }

    /// Returns the NSScreen corresponding to macOS's primary (menu bar) display, if present.
    private func getPrimaryScreen() -> NSScreen? {
        let mainDisplayID = CGMainDisplayID()
        for screen in NSScreen.screens {
            if let screenNumber = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber {
                let displayID = CGDirectDisplayID(screenNumber.uint32Value)
                if displayID == mainDisplayID {
                    return screen
                }
            }
        }
        return nil
    }

    @MainActor
    private func displayHUD(hudType: HUDType, value: Float, isMuted: Bool, resetsTimer: Bool) {
        guard isPreviewMode || isInterceptionActive else { return }
        let shouldResetTimer = resetsTimer || !isShowing
        if !shouldResetTimer, hideTimer == nil { return }
        if shouldResetTimer {
            displayGeneration += 1
            hideTimer?.invalidate()
        }

        // Create or update the HUD window
        if hudWindow == nil {
            createHUDWindow()
        }

        // Update the content view
        if let window = hudWindow {
            let shouldUpdateContent: Bool =
                switch hudType {
                case .volume:
                    hostingView == nil
                        || lastShownHUDType != hudType
                        || lastShownVolume == nil
                        || abs((lastShownVolume ?? -1) - value) > 0.0005
                        || (lastShownMuted ?? !isMuted) != isMuted

                case .brightness:
                    hostingView == nil
                        || lastShownHUDType != hudType
                        || lastShownBrightness == nil
                        || abs((lastShownBrightness ?? -1) - value) > 0.0005
                }

            // If nothing changed and the window is already visible, just extend the timer
            if window.isVisible, !shouldUpdateContent {
                window.alphaValue = 1.0
                if shouldResetTimer { scheduleHideTimer(for: hudType) }
                return
            }

            let view = HUDView(hudType: hudType, value: value, isMuted: isMuted)
            if let hostingView {
                hostingView.rootView = view
            } else {
                let hostingView = NSHostingView(rootView: view)
                hostingView.frame = window.contentView?.bounds ?? NSRect(x: 0, y: 0, width: 200, height: 200)
                hostingView.wantsLayer = true
                hostingView.layer?.backgroundColor = NSColor.clear.cgColor
                window.contentView = hostingView
                self.hostingView = hostingView
            }

            // Update position based on HUD type
            updateWindowPosition(for: hudType)

            // Show the window
            window.alphaValue = 1.0
            if !window.isVisible { window.orderFront(nil) }
            if !stationarySpaceAttached, let stationarySpace = StationarySpace.shared {
                stationarySpaceAttached = stationarySpace.add(window)
                if !stationarySpaceAttached {
                    window.level = .statusBar
                    window.collectionBehavior = [.canJoinAllSpaces, .ignoresCycle, .transient]
                    logger.error("Failed to attach HUD to stationary space; using standard overlay.")
                }
            }
            isShowing = true
        }

        if shouldResetTimer { scheduleHideTimer(for: hudType) }

        // Remember last shown state to avoid redundant view rebuilds
        lastShownHUDType = hudType
        switch hudType {
        case .volume:
            lastShownVolume = value
            lastShownMuted = isMuted

        case .brightness:
            lastShownBrightness = value
        }
    }

    @MainActor
    private func scheduleHideTimer(for hudType: HUDType) {
        hideTimer?.invalidate()
        let key = hudType == .volume ? "hudHoldSeconds" : "brightnessHUDHoldSeconds"
        let configuredHold = UserDefaults.standard.double(forKey: key)
        let hold = configuredHold > 0 ? configuredHold : 0.7
        hideTimer = Timer.scheduledTimer(withTimeInterval: hold, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.hideTimer = nil
                self?.hideHUD()
            }
        }
    }

    @MainActor
    private func createHUDWindow() {
        // Create the window with special properties for overlay
        hudWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 200, height: 200),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false,
        )

        guard let window = hudWindow else {
            logger.error("createHUDWindow: failed to create NSWindow (hudWindow is nil)")
            return
        }

        window.level = StationarySpace.shared == nil ? .statusBar : .screenSaver
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.ignoresMouseEvents = true
        window.collectionBehavior = StationarySpace.shared == nil
            ? [.canJoinAllSpaces, .ignoresCycle, .transient]
            : [.ignoresCycle]

        // Set the initial position
        updateWindowPosition()

        // Start the window hidden (only show when volume changes)
        window.orderOut(nil)

        logger.debug("Created HUD window.")
    }

    // MARK: Hide HUD

    @MainActor
    private func hideHUD() {
        guard let window = hudWindow else { return }
        let generation = displayGeneration

        // Animate fade-out before hiding
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.22
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            window.animator().alphaValue = 0.0
        } completionHandler: { [weak self] in
            Task { @MainActor [weak self] in
                guard let self, self.displayGeneration == generation else { return }
                if !self.stationarySpaceAttached {
                    window.orderOut(nil)
                    window.alphaValue = 1.0
                }
                self.isShowing = false
            }
        }
    }
}
