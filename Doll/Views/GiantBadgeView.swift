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
}

let giantBadgeSize = NSSize(width: 1000, height: 800)
let giantBadgeYOffset: CGFloat = 10

struct GiantBadgeView: View {

    @ObservedObject var controller: GiantBadgeViewController
    var onTap: (() -> Void)?

    @State private var scale: CGFloat = 0.1
    @State private var animationCounter: Int = 0
    @State private var yOffset: CGFloat = 0
    @State private var badgeInnerHoleRadius: CGFloat = 0
    @State private var badgeInnerContentOffset: CGFloat = 0

    var body: some View {
        VStack {
            Image(systemName: "arrowshape.turn.up.left.fill")
                .font(.system(size: 500))
                .foregroundColor(.red)
                .rotationEffect(.degrees(90))
                .scaleEffect(scale, anchor: .top)
                .offset(y: giantBadgeYOffset)

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
    }

    func startAnimation() {
        animationCounter &+= 1
        let newScale: CGFloat = scale == 0.5 ? 0.3 : 0.5
        // .repeatCount() modifier got weired bug in macOS(at least in Ventura), it shift the element unpexectedlly
        // so I have to do this my-self
        withAnimation(.spring()) {
            scale = newScale
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                if animationCounter < 5 {
                    startAnimation()
                } else {
                    withAnimation(.spring()) {
                        scale = 0.1
                    }
                }
            }
        }
    }
}

