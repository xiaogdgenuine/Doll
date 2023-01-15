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
        guard let activeWindow = frontmostWindowAX,
              let screenWithMouse = NSScreen.screenWithMouse else {
            return false
        }
        
        var activeWindowSizeAX: AnyObject?
        AXUIElementCopyAttributeValue(
            activeWindow, kAXSizeAttribute as CFString, &activeWindowSizeAX
        )
        if activeWindowSizeAX != nil {
            var windowSize = CGSize.zero
            AXValueGetValue(activeWindowSizeAX as! AXValue, .cgSize, &windowSize)
            
            // In Mac with notch on menubar, this is the only way I found to detect either current window is in fullscreen
            if windowSize.height == screenWithMouse.frame.size.height - (NSApplication.shared.mainMenu?.menuBarHeight ?? 0) {
                return true
            }
        }
        
        var fullScreenButton: AnyObject?
        AXUIElementCopyAttributeValue(
            activeWindow, kAXFullScreenButtonAttribute as CFString, &fullScreenButton
        )
        var fullScreenButtonPositionAX: AnyObject?
        if let fullScreenButton = fullScreenButton {
            AXUIElementCopyAttributeValue(fullScreenButton as! AXUIElement, kAXPositionAttribute as CFString, &fullScreenButtonPositionAX)
        }
        if fullScreenButtonPositionAX != nil,
           let mainScreen = NSScreen.screens.first {
            var fullScreenButtonPosition = CGPoint.zero
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
             *  Screen2.menubar.frame.maxY = 50(MainScreen.frame.maxY) - 30(Screen2.visibleFrame.maxY) = 20
             */
            let menubarYPositionThresholdInActiveScreen = mainScreen.frame.maxY - screenWithMouse.visibleFrame.maxY
            // If a window is fullscreen, it's fullscreen button(The whole toolbar actually) y offset is less than menubar.frame.maxY
            return fullScreenButtonPosition.y < menubarYPositionThresholdInActiveScreen
        }
        
        return false
    }

    static var menubarHeight: CGFloat {
        NSApplication.shared.menu?.menuBarHeight ?? 0
    }

    static var frontmostProcessId: pid_t? {
        NSWorkspace.shared.frontmostApplication?.processIdentifier
    }

    static var frontmostApplicationAX: AXUIElement? {
        guard let frontmostPid = frontmostProcessId else { return nil }
        return AXUIElementCreateApplication(frontmostPid)
    }

    static var frontmostWindowAX: AXUIElement? {
        guard let appElement = frontmostApplicationAX else { return nil }

        var frontmostWindowAX: AnyObject?
        AXUIElementCopyAttributeValue(appElement, kAXFocusedWindowAttribute as CFString, &frontmostWindowAX)

        if frontmostWindowAX != nil {
            return frontmostWindowAX as! AXUIElement
        }

        return nil
    }

}
