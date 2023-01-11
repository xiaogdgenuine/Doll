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

struct GiantBadgeView: View {

    @ObservedObject var controller: GiantBadgeViewController
    var onTap: (() -> Void)?

    @State private var scale: CGFloat = 0.1
    @State private var animationCounter: Int = 0

    var body: some View {

        ZStack(alignment: .center) {
            Circle()
                .stroke(Color.pink, lineWidth: 350)
                .scaleEffect(scale)
                .opacity(scale + 0.6)
                .shadow(radius: 10)
        }
        .contentShape(Rectangle())
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
        let newScale = scale == 0.6 ? 0.3 : 0.6
        // .repeatCount() modifier got weired bug in macOS(at least in Ventura), it shift the element unpexectedlly
        // so I have to do this my-self
        withAnimation(.spring()) {
            scale = newScale
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                if animationCounter < 5 {
                    startAnimation()
                } else {
                    withAnimation(.spring()) {
                        scale = AppSettings.showAsRedBadge ? 0.1 : 0.2
                    }
                }
            }
        }
    }
}

