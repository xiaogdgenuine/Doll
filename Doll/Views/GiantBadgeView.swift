//
//  GiantBadgeView.swift
//  Doll
//
//  Created by xiaogd on 2023/1/11.
//

import SwiftUI

class GiantBadgeViewController: ObservableObject {
    // Toggle this to zero so animation can start over again
    @Published var animationFlag = false
    @Published var isFullscreen = false
    @Published var statusItemWidth: CGFloat = 0
    @Published var statusItemHeight: CGFloat = 0
}

let giantBadgeSize = NSSize(width: 1000, height: 800)
let giantBadgeStrokeSize: CGFloat = 50

struct GiantBadgeView: View {

    @ObservedObject var controller: GiantBadgeViewController
    var onTap: (() -> Void)?

    @State private var scale: CGFloat = 1
    @State private var animationCounter: Int = 0
    @State private var yOffset: CGFloat = 0
    @State private var badgeInnerHoleRadius: CGFloat = 0
    @State private var badgeInnerContentOffset: CGFloat = 0

    var body: some View {
        let giantBadgeCircleSize = badgeInnerHoleRadius + giantBadgeStrokeSize
        let giantBadgeCenterPoint = CGPoint(x: giantBadgeCircleSize / 2, y: giantBadgeCircleSize / 2)

        VStack {
            Path { path in
                path.addArc(center: giantBadgeCenterPoint, radius: badgeInnerHoleRadius, startAngle: .zero, endAngle: .degrees(360), clockwise: false)
                path.addArc(center: giantBadgeCenterPoint, radius: giantBadgeCircleSize, startAngle: .zero, endAngle: .degrees(360), clockwise: false)
            }
            .fill(Color.red, style: FillStyle(eoFill: true))
            .opacity(scale / 10 + 0.5)
            .shadow(radius: 10)
            .scaleEffect(scale)
            .frame(width: giantBadgeCircleSize, height: giantBadgeCircleSize)
            .offset(y: yOffset)

            Spacer()
        }
        .contentShape(Rectangle())
        .frame(width: giantBadgeSize.width, height: giantBadgeSize.height)
        .onTapGesture {
            onTap?()
        }
        .onReceive(controller.$animationFlag) { _ in
            animationCounter = 0
            startAnimation()
        }
        .onReceive(controller.$isFullscreen) { isFullScreen in
            yOffset = -giantBadgeStrokeSize / 2 + (isFullScreen ? -(badgeInnerHoleRadius * 2) : -(badgeInnerHoleRadius / 2) + badgeInnerContentOffset)
        }
        .onReceive(controller.$statusItemWidth) { statusItemWidth in
            badgeInnerHoleRadius = statusItemWidth / 2 + 4
        }
        .onReceive(controller.$statusItemHeight) { statusItemHeight in
            badgeInnerContentOffset = statusItemHeight / 2
        }
    }

    func startAnimation() {
        animationCounter &+= 1
        let newScale: CGFloat = scale == 6 ? 3 : 6
        // .repeatCount() modifier got weired bug in macOS(at least in Ventura), it shift the element unpexectedlly
        // so I have to do this my-self
        withAnimation(.spring()) {
            scale = newScale
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                if animationCounter < 5 {
                    startAnimation()
                } else {
                    withAnimation(.spring()) {
                        scale = 1
                    }
                }
            }
        }
    }
}

