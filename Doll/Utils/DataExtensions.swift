//
//  NSDataExtensions.swift
//  Doll
//
//  Created by xiaogd on 2023/1/11.
//

import Foundation
import AppKit

extension Data {
    var bitmap: NSBitmapImageRep? { NSBitmapImageRep(data: self) }
}
