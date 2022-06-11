import SwiftUI

let cellSize: CGFloat = 130

struct ApplicationListView: View {
    @Binding var activeItem: AppItem?
    var allApps: [AppItem] = []
    var gridLayout = [
        GridItem(.adaptive(minimum: cellSize, maximum: cellSize), alignment: .top)]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: gridLayout, spacing: 16) {
                ForEach(allApps) { app in
                    AppItemView(item: app, activeAppItem: $activeItem)
                }
            }
        }
    }
}

struct AppItem: Identifiable {
    var id: String {
        bundleId
    }

    var bundleId: String
    var fullPath: String
    var localizedName: String
    var icon: NSImage?
}
