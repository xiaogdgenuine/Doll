import SwiftUI
import Utils
import Monitor
import LaunchAtLogin

struct ContentView: View {
    let appListService = AppListService()
    let statusBar: StatusBarController

    @State var selectedApp: AppItem?
    @State private var keyword: String = ""
    @State private var allAppItems: [AppItem] = []
    @State private var filteredAppItems: [AppItem] = []
    @State private var startAtLogin = false
    @State private var showAbout = false
    @State private var showAlertInFullScreenMode = AppSettings.showAlertInFullScreenMode

    var body: some View {
        Group {
            if showAbout {
                AboutView(open: $showAbout)
            } else {
                let keywordBinding = Binding<String>(get: {
                    keyword
                }, set: {
                    keyword = $0
                    let key = $0.lowercased()
                    filteredAppItems = allAppItems.filter { item in
                        key.isEmpty || item.localizedName.lowercased().contains(key)
                    }
                })

                let selectedAppBinding = Binding<AppItem?>(get: {
                    selectedApp
                }, set: { newSelectedApp in
                    if let newSelectedApp = newSelectedApp {
                        if let previousMonitoredAppName = statusBar.monitoredApp?.appName {
                            MonitorService.unObserve(appName: previousMonitoredAppName)
                        }

                        let newMonitoredApp = MonitoredApp(newSelectedApp.bundleId, appName: newSelectedApp.localizedName)
                        statusBar.monitoredApp = newMonitoredApp
                        MonitorEngine.monitor(app: newMonitoredApp, statusBar: statusBar)
                    }

                    selectedApp = newSelectedApp
                })

                if let monitoredApp = statusBar.monitoredApp {
                    Group {
                        Text("Monitored app: ") + Text(monitoredApp.appName)
                                .fontWeight(.heavy)
                    }
                            .padding()
                }

                VStack(alignment: .leading, spacing: 12) {
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
                            .onExitCommand {
                                statusBar.hidePopover()
                            }
                            .font(.system(size: 24))

                    LaunchAtLogin.Toggle {
                                Text("Launch at login")
                            }
                            .padding([.top])
                    Toggle("Show notification on full screen mode", isOn: $showAlertInFullScreenMode)
                            .onChange(of: showAlertInFullScreenMode) { enabled in
                                AppSettings.showAlertInFullScreenMode = enabled
                            }
                }
                        .padding()

                ApplicationListView(activeItem: selectedAppBinding, allApps: filteredAppItems)
                        .onAppear {
                            appListService.setup()
                        }
                        .onReceive(appListService.$listOfInstalledApplication) { apps in
                            allAppItems = apps.sorted {
                                        $0.localizedName.localizedCompare($1.localizedName) == .orderedAscending
                                    }
                                    .map {
                                        AppItem(bundleId: $0.bundleId, fullPath: $0.fullPath, localizedName: $0.localizedName, icon: $0.icon)
                                    }
                            filteredAppItems = allAppItems

                            if let monitoredApp = statusBar.monitoredApp {
                                selectedApp = allAppItems.first {
                                    $0.localizedName == monitoredApp.appName
                                }
                            }
                        }
                HStack {
                    if let _ = statusBar.monitoredApp {
                        Button("Stop monitor") {
                            statusBar.destroy()
                        }
                    }

                    Spacer()

                    Button("About") {
                        showAbout = true
                    }

                    Button("Quit") {
                        exit(0)
                    }
                }
                        .padding()
            }
        }
                .frame(width: 600, height: 650, alignment: .topLeading)
    }
}