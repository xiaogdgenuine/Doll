import AppKit
import Monitor
import SwiftUI

let defaultIconSize: CGFloat = 20
let defaultIcon = #imageLiteral(resourceName: "DefaultStatusBarIcon")

class StatusBarController {
    private var statusBar: NSStatusBar!
    private var statusItem: NSStatusItem!
    private var latestBadgeText = ""
    private var latestMessageCount = 0

    private var giantBadgeController = GiantBadgeViewController()
    private var giantBadgePanel = NSPanel(contentRect: NSRect(origin: .zero, size: defaultWindowSize),
                              styleMask: [.nonactivatingPanel],
                              backing: .buffered, defer: false)
    private var lastTimeShowingGiantBadge = Date()

    public var monitoredApp: MonitoredApp? {
        didSet {
            refreshIcon()
        }
    }
    private var monitoredAppIcon: NSImage?

    init() {
        setupStatusBar()
    }

    func setupStatusBar(icon: NSImage? = nil) {
        statusBar = .system
        statusItem = statusBar.statusItem(withLength: defaultIconSize)
        if let statusBarButton = statusItem.button {
            statusBarButton.sendAction(on: [.leftMouseUp, .rightMouseUp])
            statusBarButton.image = icon ?? defaultIcon
            statusBarButton.image?.size = NSSize(width: defaultIconSize, height: defaultIconSize)
            statusBarButton.image?.isTemplate = false
            statusBarButton.imagePosition = .imageLeft
            statusBarButton.action = #selector(onIconClicked(sender:))
            statusBarButton.target = self
            statusBarButton.toolTip = NSLocalizedString("Hold option key ⌥ and click to config", comment: "")
        }

        giantBadgePanel.isOpaque = false
        giantBadgePanel.hasShadow = false
        giantBadgePanel.backgroundColor = NSColor.clear
    }

    func refreshIcon() {
        monitoredAppIcon = Storage.appIcon(for: monitoredApp?.bundleId ?? "")
        updateBadgeText(latestBadgeText, force: true)
    }

    @objc func onIconClicked(sender: AnyObject) {
        hideGiantBadge()

        let noAppSelected = statusItem.button?.image == defaultIcon
        let isOptionKeyHolding = NSEvent.modifierFlags.contains(.option)
        let isRightClick = NSApp.currentEvent?.isRightClick == true

        if noAppSelected || isOptionKeyHolding || isRightClick {
            MonitorEngine.shared.showConfigWindow()
        } else if let monitoredAppName = monitoredApp?.appName,
                  let monitoredAppBundleId = monitoredApp?.bundleId {
            let appRunning = MonitorService.isMonitoredAppRunning(bundleIdentifier: monitoredAppBundleId)
            if !appRunning {
                guard let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: monitoredAppBundleId) else {
                    return
                }

                NSWorkspace.shared.open(appURL)
            } else {
                if NSWorkspace.shared.frontmostApplication?.bundleIdentifier == monitoredAppBundleId {
                    // Hide the app
                    NSWorkspace.shared.frontmostApplication?.hide()
                } else {
                    // Send the app window to front most
                    MonitorService.openMonitoredApp(appName: monitoredAppName)
                }
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
        
        guard let monitoredAppIcon = monitoredAppIcon else {
            return
        }
        if AppSettings.showAsRedBadge {
            updateBadgeIcon(icon: monitoredAppIcon, size: CGSize(width: defaultIconSize, height: defaultIconSize))
        } else {
            updateBadgeIcon(icon: monitoredAppIcon, size: CGSize(width: defaultIconSize, height: defaultIconSize))
        }

        MonitorService.observe(appName: appName) { [weak self] badge in
            let appRunning = MonitorService.isMonitoredAppRunning(bundleIdentifier: targetBundle.bundleIdentifier ?? "")
            let appIsNotRunningAndIconShouldBeHidden = AppSettings.hideWhenAppNotRunning && !appRunning
            let badgeIsEmptyAndIconShouldBeHidden = AppSettings.hideWhenNothingComing && (badge.isNil || badge?.isEmpty == true)

            if appIsNotRunningAndIconShouldBeHidden || badgeIsEmptyAndIconShouldBeHidden {
                self?.hideStatusBar()
            } else {
                self?.updateBadgeText(badge)
            }
        }
    }

    func showPopover(popover: NSPopover? = nil) {
        if let statusBarButton = statusItem.button {
            popover?.show(relativeTo: statusBarButton.bounds, of: statusBarButton, preferredEdge: .maxY)
            if let contentWindow = popover?.contentViewController?.view.window {
                // A little hack to prevent popover shitup with menubar
                // https://stackoverflow.com/a/35047661
                contentWindow.parent?.removeChildWindow(contentWindow)
            }
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

        guard !AppSettings.showOnlyAppIcon, force || statusItem.button?.title != text else {
            return
        }

        let textWidth = (text ?? "")
            .width(withConstrainedHeight: defaultIconSize, font: .systemFont(ofSize: 14))
        statusItem.length = defaultIconSize + textWidth

        // New notification comes in
        let newText = text ?? ""

        if newText.isEmpty {
            hideGiantBadge()
            hidePopover()
        }
        
        guard let monitoredAppIcon = monitoredAppIcon else {
            return
        }
        
        if AppSettings.showAsRedBadge {
            updateBadgeIcon(icon: monitoredAppIcon.addBadgeToImage(drawText: newText))
            statusItem.length = defaultIconSize
            statusItem.button?.title = ""
        } else {
            statusItem.length = defaultIconSize + textWidth
            updateBadgeIcon(icon: monitoredAppIcon, size: CGSize(width: defaultIconSize, height: defaultIconSize))
            statusItem.button?.title = newText
        }

        let newMessageCount = Int(newText) ?? 0
        if latestBadgeText != newText {
            if AppSettings.showAlertInFullScreenMode {
                tryShowTheNewNotificationPopover(newText: newText)
            }

            if AppSettings.isGiantBadgeEnabled(for: monitoredApp?.appName ?? "") {
                // Don't show giant badge when message count is decreasing
                if newMessageCount >= latestMessageCount {
                    tryShowGiantBadge(text)
                } else {
                    hideGiantBadge()
                }
            } else {
                hideGiantBadge()
            }
        }

        latestBadgeText = newText
        latestMessageCount = newMessageCount
    }

    func refreshDisplayMode() {
        if AppSettings.showOnlyAppIcon {
            statusItem.length = defaultIconSize
            statusItem.button?.title = ""
            updateBadgeIcon(icon: monitoredAppIcon, size: CGSize(width: defaultIconSize, height: defaultIconSize))
        } else {
            updateBadgeText(latestBadgeText, force: true)
        }
    }

    func updateBadgeIcon(icon: NSImage?, size: CGSize? = nil) {
        statusItem.button?.image = icon
        if let iconSize = size ?? icon?.size {
            statusItem.button?.image?.size = iconSize
        }
    }

    func tryShowGiantBadge(_ text: String?) {
        let now = Date()
        if !giantBadgePanel.isVisible || now.timeIntervalSince(lastTimeShowingGiantBadge) >= 3 {
            lastTimeShowingGiantBadge = now

            if giantBadgePanel.contentViewController != nil {
                giantBadgeController.animationFlag.toggle()
            } else {
                let giantBadgeView = GiantBadgeView(controller: giantBadgeController) { [weak self] in
                    guard let self = self else { return }
                    self.onIconClicked(sender: self)
                }
                giantBadgePanel.contentViewController = NSHostingController(rootView: giantBadgeView)
                giantBadgePanel.setContentSize(defaultWindowSize)
            }

            if let frame = NSScreen.main?.frame,
               let iconFrame = statusItem.button?.window?.frame {
                let menubarHeight = NSApplication.shared.mainMenu?.menuBarHeight ?? 0
                giantBadgePanel.setFrameOrigin(NSPoint(x: iconFrame.midX - defaultWindowSize.width / 2, y: frame.height - defaultWindowSize.height / 2 - menubarHeight / 2))
            }
            giantBadgePanel.level = .popUpMenu
            giantBadgePanel.setIsVisible(true)
            giantBadgePanel.orderFrontRegardless()
        }
    }

    func hideGiantBadge() {
        giantBadgePanel.setIsVisible(false)
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
            AppSettings.toggleGiantBadge(for: monitoredApp.appName, value: false)
        }
    }

    private func createNotificationPopover(newText: String) -> NSPopover {
        let notificationPopover = NSPopover()
        let textWidth = newText
                .width(withConstrainedHeight: defaultIconSize, font: .systemFont(ofSize: 14))
        let horizonPadding: CGFloat = 32
        let verticalPadding: CGFloat = 16
        notificationPopover.contentSize = NSSize(width: defaultIconSize + textWidth + horizonPadding, height: defaultIconSize + verticalPadding)
        notificationPopover.behavior = .transient
        notificationPopover.setValue(true, forKeyPath: "shouldHideAnchor")

        let targetApp = monitoredApp
        let view = NotificationView(icon: monitoredAppIcon ?? defaultIcon, badgeText: newText) {
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
        var activeWindowRole: AnyObject?
        AXUIElementCopyAttributeValue(appElement, kAXFocusedWindowAttribute as CFString, &frontmostWindow)

        if frontmostWindow != nil {
            let activeWindow = frontmostWindow as! AXUIElement

            AXUIElementCopyAttributeValue(
                    activeWindow, kAXRoleAttribute as CFString, &activeWindowRole
            )

            if let windowRole = activeWindowRole as? String, windowRole == "AXScrollArea" {
                // Desktop window will return AXScrollArea role, it doesn't count, as Desktop always in fullscreen mode
                return false
            }

            AXUIElementCopyAttributeValue(
                    activeWindow, kAXSizeAttribute as CFString, &activeWindowSize
            )

            if activeWindowSize != nil,
               let activeScreen = NSScreen.getScreenWithMouse() {
                var windowSize = CGSize()
                AXValueGetValue(activeWindowSize as! AXValue, .cgSize, &windowSize)

                // Second case is for new mac with notched menubar
                return windowSize.height == activeScreen.frame.size.height ||
                windowSize.height == activeScreen.frame.size.height - (NSApplication.shared.mainMenu?.menuBarHeight ?? 0)
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
