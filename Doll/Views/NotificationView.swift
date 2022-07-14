import SwiftUI
import Utils
import Monitor
import LaunchAtLogin

struct NotificationView: View {
    let icon: NSImage?
    let badgeText: String
    let onTap: () -> Void
    var body: some View {
        let iconSize: CGFloat = 20

        HStack {
            if let icon = icon {
                Image(nsImage: icon)
                        .resizable()
                        .frame(width: iconSize, height: iconSize)
            }
            Text(badgeText)
                    .fontWeight(.bold)
        }
                .padding(8)
                .contentShape(Rectangle())
                .onTapGesture {
                    onTap()
                }
    }
}
