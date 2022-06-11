import SwiftUI
import Utils
import Monitor
import LaunchAtLogin

struct AboutView: View {
    var body: some View {
        VStack {
            VStack(spacing: 32) {
                Text("About Doll")
                        .font(.title)
                Text("About author")
                Text("Icon from [Darius Dan - Flaticon](https://www.flaticon.com/free-icons/reminder)")

                HStack {
                    Text("How it works?")
                    Text("https://github.com/xiaogdgenuine/Doll")
                }

                Text("Tip me")
                Image("WeChatTipQRCode").resizable().frame(width: 300, height: 300)

            }.padding()
        }.frame(maxHeight: .infinity)
    }
}
