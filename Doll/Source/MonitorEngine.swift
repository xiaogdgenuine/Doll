import Foundation
import SwiftUI
import Monitor

let defaultWindowSize = NSSize(width: 900, height: 600)
let SETTING_MONITORED_APP_IDS = "SETTING_MONITORED_APP_IDS"

class MonitorEngine {

    static var shared = MonitorEngine()

    var configWindow = NSWindow(contentRect: NSRect(origin: .zero, size: defaultWindowSize), styleMask: [.closable, .titled], backing: .buffered, defer: false)
    var statusBars: [StatusBarController] = []
    @Published var monitoredApps: [MonitoredApp] = []

    private init() {
    }

    func setup() {
        MonitorService.setupObservers()
        
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

            MonitorEngine.shared.monitoredApps = monitoredApps

            if monitoredApps.count == 0 {
                return showConfigWindow()
            }

            monitoredApps.forEach { app in
                let statusBar = createNewStatusBar()
                statusBar.monitorApp(app: app)
                statusBars.append(statusBar)
            }
        } else {
            showConfigWindow()
        }
    }

    func monitor(newApp: MonitoredApp, at: Int?, statusBar: StatusBarController? = nil) {
        if let statusBar = statusBar,
            let oldAppIndex = at {
            statusBar.monitorApp(app: newApp)
            monitoredApps[oldAppIndex] = newApp
        } else {
            if (statusBars.contains {
                $0.monitoredApp == newApp
            }) {
                return
            }

            let firstTimeSetup = statusBars.count == 1 && statusBars[0].monitoredApp == nil
            let newStatusBar = firstTimeSetup ? statusBars[0] : createNewStatusBar()
            newStatusBar.monitorApp(app: newApp)
            statusBars.append(newStatusBar)
            monitoredApps.append(newApp)
        }

        saveSelectedApps()
    }

    func unMonitor(app: MonitoredApp) {
        statusBars = statusBars.filter {
            $0.monitoredApp != app
        }
        monitoredApps = monitoredApps.filter { $0 != app }
        saveSelectedApps()

        if statusBars.count == 0 {
            showConfigWindow()
        }
    }

    func showConfigWindow() {
        configWindow.isReleasedWhenClosed = false
        configWindow.title = NSLocalizedString("Doll - badge watcher", comment: "")
        configWindow.isOpaque = true
        configWindow.contentViewController = NSHostingController(rootView: ConfigView())
        configWindow.setContentSize(defaultWindowSize)
        configWindow.center()
        NSApp.activate(ignoringOtherApps: true)
        configWindow.makeKeyAndOrderFront(nil)
        configWindow.orderFrontRegardless()
    }

    private func saveSelectedApps() {
        let data = monitoredApps.map {
                    $0.bundleId
                }
                .joined(separator: ",")
        UserDefaults.standard.set(data, forKey: SETTING_MONITORED_APP_IDS)
        UserDefaults.standard.synchronize()
    }

    private func createNewStatusBar() -> StatusBarController {
        let newStatusBar = StatusBarController()

        return newStatusBar
    }
}

class MonitoredApp: Equatable, Identifiable {
    var id: String { UUID().uuidString }
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
