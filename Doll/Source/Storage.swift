//
//  Storage.swift
//  Doll
//
//  Created by xiaogd on 2023/1/11.
//

import Foundation
import AppKit

enum Storage {

    static let applicationDirectory = (try! FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)).appendingPathComponent(Bundle.main.bundleIdentifier!, isDirectory: true)
    static let appIconsDirectory = applicationDirectory.appendingPathComponent("app_icons")

    static func setup() {
        print("App icons store at: ", appIconsDirectory.path.removingPercentEncoding!)
        try? FileManager.default.createDirectory(atPath: appIconsDirectory.path, withIntermediateDirectories: true)
    }

    static func appIcon(for bundleId: String) -> NSImage {
        let imageURL = iconPath(for: bundleId)

        return NSImage(contentsOf: imageURL) ?? Utils.getAppIcon(bundleId: bundleId)
    }

    @discardableResult
    static func storeCustomizedAppIcon(for bundleId: String, image: NSImage) -> URL? {
        let imageURL = iconPath(for: bundleId)

        do {
            try image.png?.write(to: imageURL)
            return imageURL
        } catch {
            print("Error while storing app icon", error)
            return nil
        }
    }

    static func removeCustomizedAppIcon(for bundleId: String) {
        let imageURL = iconPath(for: bundleId)

        do {
            try FileManager.default.removeItem(at: imageURL)
        } catch {
            print("Error while deleteing app icon", error)
        }
    }
    
}

private extension Storage {
    static private func iconPath(for bundleId: String) -> URL {
        appIconsDirectory.appendingPathComponent("\(bundleId).png", isDirectory: false)
    }
}
