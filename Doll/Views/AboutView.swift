import SwiftUI
import Utils
import Monitor
import LaunchAtLogin

struct AboutView: View {
    var body: some View {
        VStack {
            VStack(spacing: 32) {
                Text(String(format: NSLocalizedString("About Doll", comment: ""), locale: nil, arguments: [Utils.appVersion]))
                        .font(.title)
                Text("Icon from [Darius Dan - Flaticon](https://www.flaticon.com/free-icons/reminder)")

                HStack {
                    Text("How it works?")
                    Text("https://github.com/xiaogdgenuine/Doll")
                }

                Text("Tip me")
                HStack {
                    Image(systemName: "cup.and.saucer")
                        .resizable()
                        .foregroundColor(.black)
                        .frame(width: 32, height: 32)
                    Text("Buy me a coffee")
                        .foregroundColor(.black)
                }
                .contentShape(Rectangle())
                .padding()
                .padding(.horizontal, 24)
                .background(Color.yellow)
                .cornerRadius(12)
                .onTapGesture {
                    NSWorkspace.shared.open(URL(string: "https://www.buymeacoffee.com/xiaogd")!)
                }
            }.padding()
        }.frame(maxHeight: .infinity)
    }
}
