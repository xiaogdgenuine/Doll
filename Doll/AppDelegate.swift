import SwiftUI

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    var appActivated = false

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        MonitorEngine.setup()
    }

    func applicationWillBecomeActive(_ notification: Notification) {
        // https://github.com/xiaogdgenuine/Doll/issues/4
        // Create new instance if the app relaunch again from Spotlight or manually open by user
        if appActivated {
            print("Activated!")
            MonitorEngine.createNewInstanceIfNecessary()
        }

        appActivated = true
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
}