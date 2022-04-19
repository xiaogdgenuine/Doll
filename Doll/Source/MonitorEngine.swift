import Foundation
import SwiftUI

let SETTING_MONITORED_APP_IDS = "SETTING_MONITORED_APP_IDS"

class MonitorEngine {
    static var statusBars: [StatusBarController] = []

    static func setup() {
        if let data = UserDefaults.standard.value(forKey: SETTING_MONITORED_APP_IDS) as? String {
            let monitoredAppIds = data.split(separator: ",").map(String.init)
            let monitoredApps: [MonitoredApp] = monitoredAppIds.map { bundleId in
                var appName = bundleId
                if let appFullPath = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId)?.absoluteURL.path,
                   let targetBundle = Bundle(path: appFullPath),
                   let name = targetBundle.object(forInfoDictionaryKey: kCFBundleNameKey as String) as? String {
                    appName = name
                }

                return MonitoredApp(bundleId, appName: appName)
            }

            if monitoredApps.count == 0 {
                return createNewInstance()
            }

            monitoredApps.forEach { app in
                let statusBar = createNewStatusBar()
                statusBar.monitorApp(app: app)
            }
        } else {
            createNewInstance()
        }
    }

    static func monitor(app: MonitoredApp, statusBar: StatusBarController? = nil) {
        if let statusBar = statusBar {
            statusBar.monitorApp(app: app)
            if statusBar.monitoredApp == nil {
                statusBar.monitoredApp = app
            }
        } else {
            if (statusBars.contains {
                $0.monitoredApp == app
            }) {
                return
            }

            let firstTimeSetup = statusBars.count == 1 && statusBars[0].monitoredApp == nil
            let newStatusBar = firstTimeSetup ? statusBars[0] : createNewStatusBar()
            newStatusBar.monitorApp(app: app)
            statusBars.forEach {
                $0.hidePopover()
            }
        }

        saveSelectedApps()
    }

    static func unMonitor(app: MonitoredApp) {
        statusBars = statusBars.filter {
            $0.monitoredApp != app
        }
        saveSelectedApps()

        if statusBars.count == 0 {
            createNewInstance()
        }
    }

    static func createNewInstanceIfNecessary() {
        if let unAssignedMonitor = (statusBars.first {
            $0.monitoredApp == nil
        }) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                unAssignedMonitor.showPopover()
            }
        } else {
            createNewInstance()
        }
    }

    static func createNewInstance() {
        let newStatusBar = createNewStatusBar()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            newStatusBar.showPopover()
        }
    }

    private static func saveSelectedApps() {
        let data = statusBars.compactMap {
                    $0.monitoredApp?.bundleId
                }
                .joined(separator: ",")
        UserDefaults.standard.set(data, forKey: SETTING_MONITORED_APP_IDS)
        UserDefaults.standard.synchronize()
    }

    private static func createNewStatusBar() -> StatusBarController {
        let popover = NSPopover()
        popover.contentSize = NSSize(width: 600, height: 500)
        popover.behavior = .transient

        let newStatusBar = StatusBarController(popover)
        statusBars.append(newStatusBar)

        let contentView = ContentView(statusBar: newStatusBar)
        popover.contentViewController = NSHostingController(rootView: contentView)

        return newStatusBar
    }
}

class MonitoredApp: Equatable {
    let bundleId: String
    let appName: String

    init(_ bundleId: String, appName: String) {
        self.bundleId = bundleId
        self.appName = appName
    }

    static func ==(lhs: MonitoredApp, rhs: MonitoredApp) -> Bool {
        lhs.bundleId == rhs.bundleId
    }
}