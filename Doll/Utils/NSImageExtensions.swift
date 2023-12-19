//
//  NSImageExtensions.swift
//  Doll
//
//  Created by huikai on 2022/6/12.
//

import AppKit
import Foundation

extension NSImage {
    var png: Data? { tiffRepresentation?.bitmap?.png }

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
            let textFont = NSFont.systemFont(ofSize: 8)
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = NSTextAlignment.center

            let textFontAttributes = [
                NSAttributedString.Key.font: textFont,
                NSAttributedString.Key.foregroundColor: textColor,
                ] as [NSAttributedString.Key : Any]

            let textRenderSize = (finalText as NSString).size(withAttributes: textFontAttributes)
            let maxAxisSizeForText = max(textRenderSize.width, textRenderSize.height)
            let badgeBackgroundSize = CGSize(width: maxAxisSizeForText + 4, height: maxAxisSizeForText + 4)
            let badgeFillColor = NSColor.systemRed.withAlphaComponent(0.9)
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

    func grayOut() -> NSImage? {
        guard let cgImage = cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return nil
        }

        let bitmap = NSBitmapImageRep(cgImage: cgImage)

        guard let grayscale = bitmap.converting(to: .genericGray, renderingIntent: .default) else {
            return nil
        }

        let grayImage = NSImage(size: size)
        grayImage.addRepresentation(grayscale)
        return grayImage
    }

    func invert() -> NSImage? {
        guard let cgImage = cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return nil
        }

        let ciImage = CIImage(cgImage: cgImage)

        guard let filter = CIFilter(name: "CIColorInvert") else {
            print("Could not create CIColorInvert filter")
            return nil
        }

        filter.setValue(ciImage, forKey: kCIInputImageKey)
        guard let outputImage = filter.outputImage else {
            print("Could not obtain output CIImage from filter")
            return nil
        }

        let context = CIContext(options: nil)
        guard let cgOutImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            return nil
        }

        return NSImage(cgImage: cgOutImage, size: size)
    }
}

extension NSBitmapImageRep {
    var png: Data? { representation(using: .png, properties: [:]) }
}
