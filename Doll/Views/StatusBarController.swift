import AppKit
import Monitor
import SwiftUI

let defaultIconSize: CGFloat = 20
let iconSizeWithBadge: CGFloat = 30
let defaultIcon = #imageLiteral(resourceName: "DefaultStatusBarIcon")

class StatusBarController {
    private var statusBar: NSStatusBar!
    private var statusItem: NSStatusItem!
    private var latestBadgeText = ""

    public var monitoredApp: MonitoredApp?

    private var iconSize: CGFloat {
        AppSettings.showAsRedBadge ? iconSizeWithBadge : defaultIconSize
    }

    init() {
        setupStatusBar()
    }

    func setupStatusBar(icon: NSImage? = nil) {
        statusBar = .system
        statusItem = statusBar.statusItem(withLength: iconSize)
        if let statusBarButton = statusItem.button {
            statusBarButton.sendAction(on: [.leftMouseUp, .rightMouseUp])
            statusBarButton.image = icon ?? defaultIcon
            statusBarButton.image?.size = NSSize(width: iconSize, height: iconSize)
            statusBarButton.image?.isTemplate = false
            statusBarButton.imagePosition = .imageLeft
            statusBarButton.action = #selector(onIconClicked(sender:))
            statusBarButton.target = self
            statusBarButton.toolTip = NSLocalizedString("Hold option key ⌥ and click to config", comment: "")
        }
    }

    @objc func onIconClicked(sender: AnyObject) {
        var appRunning = false

        if let monitoredApp = monitoredApp {
            appRunning = MonitorService.isMonitoredAppRunning(appName: monitoredApp.appName)
        }

        let noAppSelected = statusItem.button?.image == defaultIcon
        let isOptionKeyHolding = NSEvent.modifierFlags.contains(.option)
        let isRightClick = NSApp.currentEvent?.isRightClick == true

        if noAppSelected || isOptionKeyHolding || isRightClick {
            MonitorEngine.shared.showConfigWindow()
        } else if let monitoredAppName = monitoredApp?.appName,
                  let monitoredAppBundleId = monitoredApp?.bundleId {
            if !appRunning {
                guard let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: monitoredAppBundleId) else {
                    return
                }

                NSWorkspace.shared.open(appURL)
            } else {
                MonitorService.openMonitoredApp(appName: monitoredAppName)
            }
        }
    }

    func monitorApp(app: MonitoredApp) {
        monitoredApp = app

        guard let appFullPath = NSWorkspace.shared.urlForApplication(withBundleIdentifier: app.bundleId)?.absoluteURL.path else {
            return
        }

        guard let targetBundle = Bundle(path: appFullPath),
              let appName = (
                      targetBundle.object(forInfoDictionaryKey: "CFBundleDisplayName") ??
                      targetBundle.object(forInfoDictionaryKey: kCFBundleNameKey as String)) as? String else {
            return
        }

        statusItem.autosaveName = "Doll_\(app.bundleId)"
        updateBadgeText(nil)
        let originIcon = NSWorkspace.shared.icon(forFile: appFullPath)
        updateBadgeIcon(icon: AppSettings.showAsRedBadge ? originIcon.addBadgeToImage(drawText: "") : originIcon)
        hidePopover()

        MonitorService.observe(appName: appName) { [weak self] badge in
            if AppSettings.hideWhenNothingComing && (badge.isNil || badge?.isEmpty == true) {
                self?.hideStatusBar()
            } else {
                self?.updateBadgeText(badge)
            }
        }
    }

    func showPopover(popover: NSPopover? = nil) {
        if let statusBarButton = statusItem.button {
            popover?.show(relativeTo: statusBarButton.bounds, of: statusBarButton, preferredEdge: .maxY)
        }
    }

    func hidePopover(popover: NSPopover? = nil) {
        popover?.performClose(nil)
    }

    func hideStatusBar() {
        statusItem.isVisible = false
    }

    func updateBadgeText(_ text: String?, force: Bool = false) {
        statusItem.isVisible = true

        guard force || statusItem.button?.title != text else {
            return
        }

        let textWidth = (text ?? "")
                .width(withConstrainedHeight: iconSize, font: .systemFont(ofSize: 14))
        statusItem.length = iconSize + textWidth

        // New notification comes in
        let oldText = statusItem.button?.title ?? ""
        let newText = text ?? ""

        if AppSettings.showAlertInFullScreenMode && !newText.isEmpty && oldText != newText {
            tryShowTheNewNotificationPopover(newText: newText)
        }

        let originIcon = NSWorkspace.shared.icon(forFile: NSWorkspace.shared.urlForApplication(withBundleIdentifier: monitoredApp?.bundleId ?? "")?.absoluteURL.path ?? "")

        if AppSettings.showAsRedBadge {
            updateBadgeIcon(icon: originIcon.addBadgeToImage(drawText: newText))
            statusItem.length = iconSize
            statusItem.button?.title = ""
        } else {
            statusItem.length = iconSize + textWidth
            updateBadgeIcon(icon: originIcon)
            statusItem.button?.title = newText
        }
        latestBadgeText = newText
    }

    func refreshDisplayMode() {
        updateBadgeText(latestBadgeText, force: true)
    }

    func updateBadgeIcon(icon: NSImage) {
        statusItem.button?.image = icon
        statusItem.button?.image?.size = NSSize(width: iconSize, height: iconSize)
    }

    func tryShowTheNewNotificationPopover(newText: String) {
        if currentActiveWindowIsFullScreen() {
            let notificationPopover = createNotificationPopover(newText: newText)
            showPopover(popover: notificationPopover)
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
                self?.hidePopover(popover: notificationPopover)
            }
        }
    }

    func destroy() {
        if let monitoredApp = monitoredApp {
            MonitorService.unObserve(appName: monitoredApp.appName)
            MonitorEngine.shared.unMonitor(app: monitoredApp)
            statusBar.removeStatusItem(statusItem)
        }
    }

    private func createNotificationPopover(newText: String) -> NSPopover {
        let notificationPopover = NSPopover()
        let textWidth = newText
                .width(withConstrainedHeight: iconSize, font: .systemFont(ofSize: 14))
        let horizonPadding: CGFloat = 32
        let verticalPadding: CGFloat = 16
        notificationPopover.contentSize = NSSize(width: iconSize + textWidth + horizonPadding, height: iconSize + verticalPadding)
        notificationPopover.behavior = .transient
        notificationPopover.setValue(true, forKeyPath: "shouldHideAnchor")

        var extraVerticalPadding: CGFloat = 0
        if let statusBarButton = statusItem.button,
           let statusBarWindow = statusBarButton.window,
           let activeScreenSize = (NSScreen.main ?? NSScreen.getScreenWithMouse())?.frame {
            // Calculate the extra padding in order to make sure popover content fully displayed
            let buttonRect = statusBarButton.convert(statusBarButton.bounds, to: nil)
            let buttonOrigin = statusBarWindow.convertPoint(toScreen: NSPoint(x: buttonRect.minX, y: buttonRect.minY))
            extraVerticalPadding = max(buttonOrigin.y - activeScreenSize.height - statusBarButton.bounds.height + 8, 0)
        }


        let targetApp = monitoredApp
        let view = NotificationView(icon: statusItem.button?.image, badgeText: newText, extraVerticalPadding: extraVerticalPadding) {
            if let monitoredAppName = targetApp?.appName {
                MonitorService.openMonitoredApp(appName: monitoredAppName)
            }
        }
        notificationPopover.contentViewController = NSHostingController(rootView: view)

        return notificationPopover
    }
}

extension StatusBarController {
    func currentActiveWindowIsFullScreen() -> Bool {
        guard let frontmostPid = NSWorkspace.shared.frontmostApplication?.processIdentifier else {
            return false
        }

        let appElement = AXUIElementCreateApplication(frontmostPid)
        var frontmostWindow: AnyObject?
        var activeWindowSize: AnyObject?
        AXUIElementCopyAttributeValue(appElement, kAXFocusedWindowAttribute as CFString, &frontmostWindow)

        if frontmostWindow != nil {
            let activeWindow = frontmostWindow as! AXUIElement
            AXUIElementCopyAttributeValue(
                    activeWindow, kAXSizeAttribute as CFString, &activeWindowSize
            );

            if activeWindowSize != nil,
               let activeScreen = NSScreen.getScreenWithMouse() {
                var windowSize = CGSize()
                AXValueGetValue(activeWindowSize as! AXValue, .cgSize, &windowSize)
                return windowSize == activeScreen.frame.size
            }
        }

        return false
    }
}

extension String {
    func width(withConstrainedHeight height: CGFloat, font: NSFont) -> CGFloat {
        let constraintRect = CGSize(width: .greatestFiniteMagnitude, height: height)
        let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: font], context: nil)

        return ceil(boundingBox.width)
    }
}

extension NSScreen {
    static func getScreenWithMouse() -> NSScreen? {
        let mouseLocation = NSEvent.mouseLocation
        let screens = NSScreen.screens
        let screenWithMouse = (screens.first {
            NSMouseInRect(mouseLocation, $0.frame, false)
        })

        return screenWithMouse
    }
}
