//
//  Utils.swift
//  Doll
//
//  Created by huikai on 2022/6/11.
//

import Foundation
import AppKit

enum Utils {

    static func getAppIcon(bundleId: String) -> NSImage {
        let defaultIcon = #imageLiteral(resourceName: "DefaultStatusBarIcon")
        guard let appFullPath = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId)?.absoluteURL.path else {
            return defaultIcon
        }

        return NSWorkspace.shared.icon(forFile: appFullPath)
    }

    static var currentActiveWindowIsFullScreen: Bool {
        guard let activeWindow = frontmostWindow else {
            return false
        }

        var activeWindowRole: AnyObject?
        AXUIElementCopyAttributeValue(
            activeWindow, kAXRoleAttribute as CFString, &activeWindowRole
        )

        if let windowRole = activeWindowRole as? String, windowRole == "AXScrollArea" {
            // Desktop window will return AXScrollArea role, it doesn't count, as Desktop always in fullscreen mode
            return false
        }

        var fullScreenButton: AnyObject?
        AXUIElementCopyAttributeValue(
            activeWindow, kAXFullScreenButtonAttribute as CFString, &fullScreenButton
        )
        var fullScreenButtonPositionAX: AnyObject?
        if let fullScreenButton = fullScreenButton {
            AXUIElementCopyAttributeValue(fullScreenButton as! AXUIElement, kAXPositionAttribute as CFString, &fullScreenButtonPositionAX)
        }
        var fullScreenButtonPosition = CGPoint.zero
        if fullScreenButtonPositionAX != nil,
        let screenWithMouse = NSScreen.screenWithMouse,
           let mainScreen = NSScreen.main {
            AXValueGetValue(fullScreenButtonPositionAX as! AXValue, .cgPoint, &fullScreenButtonPosition)

            // If mac connected to multiple displays,

            /*
             * Which coordinator system kAXPositionAttribute value use:
             *
             * 0, 0 (Main screen's top-left corner)
             *  ┌── ── ── ── ── ── ── ── ── ── ── ── ── ─►
             *  │
             *  │
             *  │
             *  │
             *  │
             *  │
             *  │
             *  │
             *  │
             *  │
             *  │
             *  ▼
             *
             * The coordinator system macOS used to arrange multiple screens (https://stackoverflow.com/a/14779155/2357513):
             *                        ▲
             *                        │
             *                        │
             *                        │
             *                        │
             *    ┌───────────────────┤
             *    │                   │
             *    │                   ├────────────┐
             *    │                   │            │
             *    │                   │            ├─────────────┐
             *    │   Third Screen    │            │             │
             *    │                   │ Main Screen│             │
             *    │                   │            │             │
             *    │                   │            │Second Screen│
             *    └───────────────────┴────────────┼─────────────┼─►
             * -200, 0               0, 0          │             │
             * (Screen.frame.origin)               └─────────────┘
             *                                  50, -20(Screen.frame.origin)
             *
             * So a coordinator converting logic is needed:
             *  ▲
             *  │
             *  │
             *  │
             *  │
             *  │
             *  │
             *  ├────────────┐
             *  │            │
             *  │   Menubar  ├─────────────┐
             *  ├────────────┤    Menubar  │
             *  │  50 x 50   ├─────────────┤
             *  │            │             │
             *  │            │  50 x 50    │
             *  └────────────┼─────────────┼─►
             * 0, 0          │             │
             *               └─────────────┘
             *            50, -20(Screen2.frame.origin)
             *
             *
             *  Screen2.visibleFrame.minY = -20
             *  Screen2.visibleFrame.maxY = -20 + 50(Screen2.visibleFrame.height) = 30
             *  Screen2.menubar.frame.maxY = 50(MainScreen.frame.height) - 30(Screen2.visibleFrame.maxY) = 20
             */
            let menubarYPositionThresholdInActiveScreen = mainScreen.frame.height - screenWithMouse.visibleFrame.maxY

            // If a window is fullscreen, it's fullscreen button(The whole toolbar actually) y offset is less than menubar.frame.maxY
            return fullScreenButtonPosition.y < menubarYPositionThresholdInActiveScreen
        }

        return false
    }

    static var frontmostProcessId: pid_t? {
        NSWorkspace.shared.frontmostApplication?.processIdentifier
    }

    static var frontmostWindow: AXUIElement? {

        guard let frontmostPid = frontmostProcessId else {
            return nil
        }

        let appElement = AXUIElementCreateApplication(frontmostPid)
        var frontmostWindow: AnyObject?
        AXUIElementCopyAttributeValue(appElement, kAXFocusedWindowAttribute as CFString, &frontmostWindow)

        if frontmostWindow != nil {
            return frontmostWindow as! AXUIElement
        }

        return nil
    }

}
