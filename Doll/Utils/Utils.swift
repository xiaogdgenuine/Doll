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

}
