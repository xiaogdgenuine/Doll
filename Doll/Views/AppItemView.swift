import SwiftUI

struct AppItemView: View {
    let item: AppItem
    @Binding var activeAppItem: AppItem?
    @State private var hovered: Bool = false
    var selected: Bool {
        activeAppItem?.id == item.id
    }
    var showObserveNewAppBtn: Bool {
        !selected && hovered && activeAppItem != nil
    }

    var body: some View {
        ZStack {
            VStack {
                Image(nsImage: NSWorkspace.shared.icon(forFile: item.fullPath))
                        .resizable()
                        .frame(width: 48, height: 48)
                Text(item.localizedName)
                        .if(hovered || selected) { $0.foregroundColor(Color.white) }
                        .multilineTextAlignment(.center)
            }
                    .frame(minWidth: 0,
                            maxWidth: .infinity,
                            minHeight: 0,
                            maxHeight: .infinity)
                    .padding()
                    .contentShape(Rectangle())
                    .onHover { isHovered in
                        hovered = isHovered
                    }
                    .onTapGesture {
                        activeAppItem = item
                    }.background((hovered ? Color.gray : selected ? Color.blue : Color.clear).opacity(0.3))
            
                
            if showObserveNewAppBtn {
                VStack {
                    HStack {
                        Spacer()
                        Button {
                            MonitorEngine.monitor(app: MonitoredApp(item.bundleId, appName: item.localizedName))
                        } label: {
                            Image(systemName: "plus.square.fill")
                                    .resizable()
                                    .frame(width: 16, height: 16)
                        }
                                .buttonStyle(.plain)
                                .help("Create new monitor")
                    }.padding(EdgeInsets(top: 8, leading: 0, bottom: 0, trailing: 8))
                    Spacer()
                }
            }
        }
    }
}
