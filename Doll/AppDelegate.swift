import SwiftUI

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        Storage.setup()
        MonitorEngine.shared.setup()
        HotkeyManager.setup()

       if AXIsProcessTrustedWithOptions(["AXTrustedCheckOptionPrompt": true] as CFDictionary) {
           print("Trusted by client")
       }
    }

    func applicationWillBecomeActive(_ notification: Notification) {
        // https://github.com/xiaogdgenuine/Doll/issues/4
        // Create new instance if the app relaunch again from Spotlight or manually open by user
        MonitorEngine.shared.showConfigWindow()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
}
