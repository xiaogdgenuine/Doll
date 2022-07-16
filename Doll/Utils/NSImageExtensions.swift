//
//  NSImageExtensions.swift
//  Doll
//
//  Created by huikai on 2022/6/12.
//

import AppKit
import Foundation

extension NSImage {

    func addBadgeToImage(drawText text: String) -> NSImage {
        let canvasWidth = defaultIconSize
        let canvasHeight = defaultIconSize
        let canvasSize = NSSize(width: canvasWidth, height: canvasHeight)
        let targetImage = NSImage(size: canvasSize, flipped: false) { (dstRect: CGRect) -> Bool in
            let iconSize = text.isEmpty ? defaultIconSize : defaultIconSize - 2
            self.draw(in: CGRect(origin: .zero, size: NSSize(width: iconSize, height: iconSize)))

            guard !text.isEmpty else {
                return true
            }

            let textColor = NSColor.white
            let finalText = text.count > 2 ? "99." : text
            let badgePaddingHorizental: CGFloat = 8
            let badgePaddingVertical: CGFloat = text.count == 1 ? 5 : text.count == 2 ? 8 : 9
            let textFont = NSFont.systemFont(ofSize: finalText.count > 2 ? 6 : 8)
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = NSTextAlignment.center

            let textFontAttributes = [
                NSAttributedString.Key.font: textFont,
                NSAttributedString.Key.foregroundColor: textColor,
                ] as [NSAttributedString.Key : Any]

            let textRenderSize = (finalText as NSString).size(withAttributes: textFontAttributes)
            let badgeBackgroundSize = NSSize(width: textRenderSize.width + badgePaddingHorizental, height: textRenderSize.height + badgePaddingVertical)
            let badgeFillColor = NSColor.red.withAlphaComponent(0.85)
            let badgeBackgroundRect = CGRect(origin: CGPoint(x: canvasWidth - badgeBackgroundSize.width, y: canvasHeight - badgeBackgroundSize.height), size: badgeBackgroundSize)
            let badgeBackgroundPath = NSBezierPath(ovalIn: badgeBackgroundRect)
            badgeFillColor.setFill()
            badgeBackgroundPath.fill()

            let textOrigin = CGPoint(x: badgeBackgroundRect.minX + (badgeBackgroundSize.width - textRenderSize.width) / 2, y: -((badgeBackgroundSize.height - textRenderSize.height) / 2))
            let textRect = CGRect(origin: textOrigin, size: canvasSize)
            finalText.draw(in: textRect, withAttributes: textFontAttributes)

            return true
        }
        return targetImage
    }
}
