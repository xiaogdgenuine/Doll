//
//  MonitorConfigView.swift
//  Doll
//
//  Created by huikai on 2022/6/10.
//

import SwiftUI
import Utils
import Monitor
import Introspect

struct MonitorConfigView: View {
    var isAddMode = false
    let itemIndex: Int?
    let appListService = AppListService.shared

    @State var destroyed = false
    @State var statusBar: StatusBarController?
    @State var selectedApp: MonitoredApp?
    @State var selectedAppItem: AppItem?
    @State var showGiantBadge: Bool = false
    @State var iconIsMask: Bool = false
    @State var keyword: String = ""
    @State private var defaultFocusSet = false
    @State private var allAppItems: [AppItem] = []
    @State private var filteredAppItems: [AppItem] = []
    
    var body: some View {
        if !destroyed {
            let keywordBinding = Binding<String>(get: {
                keyword
            }, set: {
                keyword = $0
                filter()
            })

            let selectedAppBinding = Binding<AppItem?>(get: {
                selectedAppItem
            }, set: { newSelectedAppItem in
                if let newSelectedAppItem = newSelectedAppItem {
                    if let previousMonitoredAppName = selectedApp?.appName, !isAddMode {
                        MonitorService.unObserve(appName: previousMonitoredAppName)
                    }

                    let newMonitoredApp = MonitoredApp(newSelectedAppItem.bundleId, appName: newSelectedAppItem.localizedName)
                    MonitorEngine.shared.monitor(newApp: newMonitoredApp, at: itemIndex, statusBar: statusBar)

                    if selectedApp == nil {
                        statusBar = MonitorEngine.shared.statusBars.last
                    }
                    selectedApp = newMonitoredApp
                }

                selectedAppItem = newSelectedAppItem
            })

            VStack {

                HStack {
                    TextField("", text: keywordBinding)
                            .placeholder(when: keyword.isEmpty) {
                                Text("Select an app to monitor it's badge")
                                        .selfSizeMask(
                                                LinearGradient(
                                                        gradient: Gradient(colors: [.blue, .red, .orange]),
                                                        startPoint: .leading,
                                                        endPoint: .trailing)
                                        )
                            }
                            .textFieldStyle(.plain)
                            .font(.system(size: 24))
                            .introspectTextField {
                                if !defaultFocusSet {
                                    defaultFocusSet = true
                                    $0.becomeFirstResponder()
                                }
                            }
                    
                    Button("Pick") {
                        pickApplication()
                    }
                }
                .padding()

                HStack {
                    if !isAddMode, let selectedApp = selectedApp {

                        Toggle("Invert the icon color base on menubar theme", isOn: $iconIsMask)
                            .onChange(of: iconIsMask) { enabled in
                                AppSettings.toggleIconMask(for: selectedApp.appName, value: enabled)
                                 MonitorEngine.shared.statusBars.forEach {
                                    $0.refreshIcon()
                                }
                            }
                            .onAppear {
                                iconIsMask = AppSettings.isIconMask(for: selectedApp.appName)
                            }

                        Toggle("Show a red arrow so you don't miss any notifications! :)", isOn: $showGiantBadge)
                            .onChange(of: showGiantBadge) { enabled in
                                AppSettings.toggleGiantBadge(for: selectedApp.appName, value: enabled)
                            }
                            .onAppear {
                                showGiantBadge = AppSettings.isGiantBadgeEnabled(for: selectedApp.appName)
                            }

                        Spacer()
                    }
                }
                .padding()

                ApplicationListView(activeItem: selectedAppBinding, allApps: filteredAppItems)
                        .onAppear {
                            loadData()
                        }
                        .onReceive(appListService.$listOfInstalledApplication) { apps in
                            allAppItems = apps.sorted {
                                        $0.localizedName.localizedCompare($1.localizedName) == .orderedAscending
                                    }
                                    .map {
                                        AppItem(bundleId: $0.bundleId, fullPath: $0.fullPath, localizedName: $0.localizedName, icon: $0.icon)
                                    }
                            filteredAppItems = allAppItems
                            keyword = selectedApp?.appName ?? ""
                            filter()

                            if let monitoredApp = selectedApp {
                                selectedAppItem = allAppItems.first {
                                    $0.bundleId == monitoredApp.bundleId
                                }
                            }
                        }

                HStack {

                    if !isAddMode, let selectedApp = selectedApp {

                        Spacer()

                        Button {
                            statusBar?.destroy()
                            destroyed = true
                        } label: {
                            Text("Stop monitoring") + Text(" - \"\(selectedApp.appName)\"")
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                        }
                    }
                }
                        .padding()
            }
        }
    }

    private func loadData() {
        appListService.setup()
    }

    private func filter() {
        let key = keyword.lowercased()
        filteredAppItems = allAppItems.filter { item in
            key.isEmpty || item.localizedName.lowercased().contains(key)
        }
    }
    
    private func pickApplication() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.application]
        panel.allowsMultipleSelection = false
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        if panel.runModal() == .OK, let appURL = panel.url {
            guard let appBundle = Bundle(url: appURL),
                  let appName = (appBundle.infoDictionary?["CFBundleDisplayName"] ?? appBundle.infoDictionary?["CFBundleName"]) as? String else {
                return
            }
            if let previousMonitoredAppName = selectedApp?.appName, !isAddMode {
                MonitorService.unObserve(appName: previousMonitoredAppName)
            }

            let newMonitoredApp = MonitoredApp(appBundle.bundleIdentifier ?? "", appName: appName)
            MonitorEngine.shared.monitor(newApp: newMonitoredApp, at: itemIndex, statusBar: statusBar)

            if selectedApp == nil {
                statusBar = MonitorEngine.shared.statusBars.last
            }
            selectedApp = newMonitoredApp
        }
    }
}
