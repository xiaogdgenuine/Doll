import AppKit
import Combine

let checkInterval: TimeInterval = 1.0

public struct MonitorService {
    public static let observerStatus = PassthroughSubject<Bool, Never>()
    private static var observedAppInfos: [String: ObservedAppInfo] = [:]
    private static var timer: Timer?
    private static var allObserversConfigured = false
    private static var appCreateObserver: AXObserver!
    private static var appDestroyObserver: AXObserver!
    private static let onElementCreateCallback = ObserverCallbackInfo {
        reloadAppElements()
    }
    private static let onElementDestroyCallback = ObserverCallbackInfo {
        observedAppInfos.keys.forEach { appName in
            if let appElement = observedAppInfos[appName]?.appElement {
                var title: AnyObject?
                AXUIElementCopyAttributeValue(appElement, kAXTitleAttribute as CFString, &title)

                // If we can't get the title from cachedTargetAppElement, then the app is terminated.
                if title as? String == nil {
                    observedAppInfos[appName]?.onBadgeUpdate(nil)
                    observedAppInfos[appName]?.updateAppElement(nil)
                }
            }
        }
    }

    public static func setupObservers() {
        timer = Timer.scheduledTimer(withTimeInterval: checkInterval, repeats: true) { timer in
            if appCreateObserver == nil || appDestroyObserver == nil {
                setupAxObserversOnDock()
            }

            observedAppInfos.keys.forEach { appName in
                observedAppInfos[appName]?.onBadgeUpdate(getBadgeText(appName: appName))
            }
        }
        timer?.fire()
    }

    public static func observe(appName: String, onUpdate: @escaping (String?) -> Void) {
        observedAppInfos[appName] = ObservedAppInfo(appElement: tryGetTargetAppElement(appName: appName), onBadgeUpdate: onUpdate)
    }

    public static func unObserve(appName: String) {
        print("Un observe \(appName)")
        observedAppInfos.removeValue(forKey: appName)
    }

    public static func openMonitoredApp(appName: String) {
        if let cachedTargetAppElement = observedAppInfos[appName]?.appElement {
            AXUIElementPerformAction(cachedTargetAppElement, kAXPressAction as CFString)
        }
    }

    public static func isMonitoredAppRunning(appName: String) -> Bool {
        if let cachedTargetAppElement = observedAppInfos[appName]?.appElement {
            var title: AnyObject?
            AXUIElementCopyAttributeValue(cachedTargetAppElement, kAXTitleAttribute as CFString, &title)

            return title as? String != nil
        }

        return false
    }

    public static func getBadgeText(appName: String) -> String? {
        guard let targetAppElement = observedAppInfos[appName]?.appElement else {
            return nil
        }

        var statusLabel: AnyObject?
        AXUIElementCopyAttributeValue(targetAppElement, "AXStatusLabel" as CFString, &statusLabel)

        return statusLabel as? String
    }

    private static func tryGetTargetAppElement(appName: String) -> AXUIElement? {
        guard let dockProcessId = NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.dock").last?.processIdentifier else {
            return nil
        }

        let dock = AXUIElementCreateApplication(dockProcessId)
        guard let dockChildren = getSubElements(root: dock) else {
            return nil
        }

        // Get badge text by lookup dock elements
        for child in dockChildren {
            var title: AnyObject?

            AXUIElementCopyAttributeValue(child, kAXTitleAttribute as CFString, &title)
            if let titleStr = title as? String,
               titleStr == appName {
                return child
            }
        }

        return nil
    }

    private static func getSubElements(root: AXUIElement) -> [AXUIElement]? {
        var childrenCount: CFIndex = 0
        var err = AXUIElementGetAttributeValueCount(root, "AXChildren" as CFString, &childrenCount)
        var result: [AXUIElement] = []

        if case .success = err {
            var subElements: CFArray?;
            err = AXUIElementCopyAttributeValues(root, "AXChildren" as CFString, 0, childrenCount, &subElements)
            if case .success = err {
                if let children = subElements as? [AXUIElement] {
                    result.append(contentsOf: children)
                    children.forEach { element in
                        if let nestedChildren = getSubElements(root: element) {
                            result.append(contentsOf: nestedChildren)
                        }
                    }
                }

                return result
            }
        }

        print("Error \(err.rawValue)")
        return nil
    }

    private static func setupAxObserversOnDock() {
        guard let dockProcessId = NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.dock").last?.processIdentifier else {
            return
        }

        AXObserverCreateWithInfoCallback(dockProcessId, { (observer, element, notification, userData, refCon) in
            if let refCon = refCon {
                let callbackInfo = Unmanaged<ObserverCallbackInfo>.fromOpaque(refCon).takeUnretainedValue()
                callbackInfo.callback()
            }
        }, &appCreateObserver)

        AXObserverCreateWithInfoCallback(dockProcessId, { (observer, element, notification, userData, refCon) in
            if let refCon = refCon {
                let callbackInfo = Unmanaged<ObserverCallbackInfo>.fromOpaque(refCon).takeUnretainedValue()
                callbackInfo.callback()
            }
        }, &appDestroyObserver)

        if let observer = appCreateObserver {
            let callbackPTR = UnsafeMutableRawPointer(Unmanaged.passUnretained(onElementCreateCallback).toOpaque())

            if AXObserverAddNotification(observer, AXUIElementCreateApplication(dockProcessId), kAXCreatedNotification as CFString, callbackPTR) == .success {
                print("Successfully added element created Notification!")
            } else {
                appCreateObserver = nil
            }

            CFRunLoopAddSource(RunLoop.current.getCFRunLoop(), AXObserverGetRunLoopSource(observer), CFRunLoopMode.defaultMode)
        }

        if let observer = appDestroyObserver {
            let callbackPTR = UnsafeMutableRawPointer(Unmanaged.passUnretained(onElementDestroyCallback).toOpaque())

            if AXObserverAddNotification(observer, AXUIElementCreateApplication(dockProcessId), kAXUIElementDestroyedNotification as CFString, callbackPTR) == .success {
                print("Successfully added element destroyed Notification!")
            } else {
                appDestroyObserver = nil
            }

            CFRunLoopAddSource(RunLoop.current.getCFRunLoop(), AXObserverGetRunLoopSource(observer), CFRunLoopMode.defaultMode)
        }

        observerStatus.send(appCreateObserver != nil)
        if appCreateObserver != nil && appDestroyObserver != nil {
            reloadAppElements()
        }
    }

    private static func reloadAppElements() {
        observedAppInfos.keys.forEach { appName in
            let info = observedAppInfos[appName]
            observedAppInfos[appName]?.updateAppElement(info?.appElement ?? tryGetTargetAppElement(appName: appName))
        }
    }
}

private struct ObservedAppInfo {
    var appElement: AXUIElement?
    let onBadgeUpdate: (String?) -> Void

    mutating func updateAppElement(_ element: AXUIElement?) {
        appElement = element
    }
}

private class ObserverCallbackInfo {
    var callback: () -> Void

    init(callback: @escaping () -> Void) {
        self.callback = callback
    }
}
