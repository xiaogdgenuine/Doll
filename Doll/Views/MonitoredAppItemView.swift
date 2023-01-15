//
//  MonitoredAppItemView.swift
//  Doll
//
//  Created by xiaogd on 2023/1/11.
//

import SwiftUI

struct MonitoredAppItemView: View {
    var appItem: MonitoredApp
    @State private var hovering = false
    @State private var renderFlag = false

    var body: some View {
        HStack {

            let hoverIcon = Image(systemName: "photo")
                .foregroundColor(.white)
                .background(Color.black.opacity(0.8).frame(width: 40, height: 40))
            Image(nsImage: Storage.appIcon(for: appItem.bundleId))
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 40, height: 40)
                .overlay(hovering ? hoverIcon : nil)
                .help("Change icon")
                .onHover { hovering = $0 }
                .onTapGesture {
                    pickIconFile()
                }
                .id(renderFlag)

            Text(appItem.appName)
        }.padding(.vertical, 8)
    }

    func pickIconFile() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.png, .jpeg, .application]
        panel.canChooseFiles = true
        panel.canChooseDirectories = false

        if panel.runModal() == .OK, let url = panel.url {
            if let image = NSImage(contentsOf: url) {
                Storage.storeCustomizedAppIcon(for: appItem.bundleId, image: image)
            } else {
                if let rep = NSWorkspace.shared.icon(forFile: url.path)
                    .bestRepresentation(for: NSRect(x: 0, y: 0, width: 1024, height: 1024), context: nil, hints: nil) {
                    let appIcon = NSImage(size: rep.size)
                    appIcon.addRepresentation(rep)
                    Storage.storeCustomizedAppIcon(for: appItem.bundleId, image: appIcon)
                }
            }

            MonitorEngine.shared.statusBars.forEach {
                $0.refreshIcon()
            }
            renderFlag.toggle()
        }
    }
}
