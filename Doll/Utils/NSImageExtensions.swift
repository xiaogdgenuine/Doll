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
        let canvasWidth = self.size.width + 8
        let canvasHeight = self.size.height
        let canvasSize = NSSize(width: canvasWidth, height: canvasHeight)
        let targetImage = NSImage(size: NSSize(width: canvasWidth, height: canvasHeight), flipped: false) { (dstRect: CGRect) -> Bool in

            self.draw(in: CGRect(origin: dstRect.origin.applying(.init(translationX: 6, y: 4)), size: NSSize(width: self.size.width - 6, height: self.size.height - 10)))

            guard !text.isEmpty else {
                return true
            }

            let textColor = NSColor.white
            let finalText = text.count > 2 ? "99." : text
            let badgePaddingHorizental: CGFloat = text.count > 1 ? 8 : 12
            let badgePaddingVertical: CGFloat = text.count > 1 ? 5 : 9
            let textFont = NSFont.systemFont(ofSize: finalText.count > 2 ? 9 : 10)
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = NSTextAlignment.center

            let textFontAttributes = [
                NSAttributedString.Key.font: textFont,
                NSAttributedString.Key.foregroundColor: textColor,
                ] as [NSAttributedString.Key : Any]

            let textRenderSize = (finalText as NSString).size(withAttributes: textFontAttributes)
            let badgeBackgroundSize = NSSize(width: textRenderSize.width + badgePaddingHorizental, height: textRenderSize.width + badgePaddingVertical)
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
