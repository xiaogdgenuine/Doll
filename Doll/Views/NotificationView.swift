import SwiftUI
import Utils
import Monitor
import LaunchAtLogin

struct NotificationView: View {
    let icon: NSImage?
    let badgeText: String
    let onTap: () -> Void
    var body: some View {
        let iconSize: CGFloat = 21

        HStack {
            if let icon = icon {
                Image(nsImage: icon)
                        .resizable()
                        .frame(width: iconSize, height: iconSize)
            }
            Text(badgeText)
                    .fontWeight(.bold)
        }
                .padding(EdgeInsets(top: NSStatusBar.system.thickness + 12, leading: 8, bottom: 8, trailing: 8))
                .contentShape(Rectangle())
                .onTapGesture {
                    onTap()
                }
    }
}
