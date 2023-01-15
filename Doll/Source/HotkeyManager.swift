//
//  HotKey.swift
//  Doll
//
//  Created by xiaogd on 2023/1/10.
//

import Foundation
import KeyboardShortcuts

enum HotkeyManager {
    static func setup() {
        KeyboardShortcuts.onKeyUp(for: .toggleConfigWindow) {
            MonitorEngine.shared.showConfigWindow()
        }
    }
}

extension KeyboardShortcuts.Name {
    static let toggleConfigWindow = Self("toggleConfigWindow", default: .init(.d, modifiers: [.command, .shift]))
}
