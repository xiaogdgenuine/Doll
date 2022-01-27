import SwiftUI
import Utils
import Monitor
import LaunchAtLogin

struct AboutView: View {
    @Binding var open: Bool
    var body: some View {
        VStack {
            Group {
                Text("About Doll")
                        .font(.title)
                Text("Icon from [Darius Dan - Flaticon](https://www.flaticon.com/free-icons/reminder)")

                Text("[How it works](https://example.com)")

                Text("Like it? Tip me to show your love!:)")
                Image("WeChatTipQRCode").resizable().frame(width: 300, height: 300)

            }.padding()

            Spacer()

            HStack {
                Spacer()
                Button("Close") {
                    open = false
                }
            }.padding()
        }.frame(maxHeight: .infinity)
    }
}

struct AboutView_Previews: PreviewProvider {
    static var previews: some View {
        AboutView(open: .constant(true))
    }
}