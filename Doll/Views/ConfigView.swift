//
//  ConfigView.swift
//  Doll
//
//  Created by huikai on 2022/6/10.
//

import SwiftUI
import LaunchAtLogin
import Monitor

struct ConfigView: View {

    @State private var failedToSetupObservers = false
    @State private var presentingPermissionGuidline = false
    @State private var items: [MonitoredApp] = []
    @State private var showingSetupView = false
    @State private var showAboutPage = false

    @State private var startAtLogin = false
    @State private var hideWhenNothingComing = AppSettings.hideWhenNothingComing
    @State private var showAlertInFullScreenMode = AppSettings.showAlertInFullScreenMode
    @State private var showAsRedBadge = AppSettings.showAsRedBadge
    @State private var showOnlyAppIcon = AppSettings.showOnlyAppIcon

    var body: some View {
        NavigationView {
            VStack {
                if items.isEmpty {
                    Text("Add monitor guideline")
                        .font(.title)
                        .padding()
                        .frame(minWidth: 250)
                } else {
                    List {
                        ForEach(Array(items.enumerated()), id: \.element.id) { (itemIndex, item) in
                            NavigationLink {
                                let statusBar = MonitorEngine.shared.statusBars.first {
                                    $0.monitoredApp == item
                                }
                                MonitorConfigView(itemIndex: itemIndex, statusBar: statusBar, selectedApp: item)
                            } label: {
                                HStack {
                                    Image(nsImage: Utils.getAppIcon(bundleId: item.bundleId))
                                        .resizable()
                                        .frame(width: 20, height: 20)
                                    Text(item.appName)
                                }.padding(.vertical, 8)
                            }
                        }
                    }.frame(minWidth: 250)
                }

                Spacer()

                VStack(alignment: .leading, spacing: 12) {
                    LaunchAtLogin.Toggle {
                                Text("Launch at login")
                            }
                            .padding([.top])

                    Group {
                        Toggle("Hide icons when there are no new notifications", isOn: $hideWhenNothingComing)
                                .onChange(of: hideWhenNothingComing) { enabled in
                                    AppSettings.hideWhenNothingComing = enabled
                                }
                        Toggle("Show notification on full screen mode", isOn: $showAlertInFullScreenMode)
                                .onChange(of: showAlertInFullScreenMode) { enabled in
                                    AppSettings.showAlertInFullScreenMode = enabled
                                }
                        Toggle("Show as red badge", isOn: $showAsRedBadge)
                                .onChange(of: showAsRedBadge) { enabled in
                                    AppSettings.showAsRedBadge = enabled
                                    MonitorEngine.shared.statusBars.forEach {
                                        $0.refreshDisplayMode()
                                    }
                                }
                    }.disabled(showOnlyAppIcon)
                    
                    Toggle("Show only app icon", isOn: $showOnlyAppIcon)
                            .onChange(of: showOnlyAppIcon) { enabled in
                                AppSettings.showOnlyAppIcon = enabled
                                MonitorEngine.shared.statusBars.forEach {
                                    $0.refreshDisplayMode()
                                }
                            }
                }
                        .padding()

                HStack {
                    NavigationLink {
                        MonitorConfigView(isAddMode: true, itemIndex: nil, statusBar: nil)
                    } label: {
                        Image(systemName: "plus")
                    }

                    if failedToSetupObservers {
                        Button {
                            presentingPermissionGuidline = true
                        } label: {
                            Image(systemName: "eye.trianglebadge.exclamationmark")
                                .foregroundColor(Color.yellow)
                        }.sheet(isPresented: $presentingPermissionGuidline) {
                            VStack {
                                Text("Permission grant guideline")
                                    .font(.title)
                                    .padding()

                                HStack {
                                    Button("Open System Preferences") {
                                        presentingPermissionGuidline = false
                                        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
                                    }

                                    Button("OK") {
                                        presentingPermissionGuidline = false
                                    }
                                }
                            }.padding()
                        }
                    }

                    Spacer()

                    NavigationLink {
                        AboutView()
                    } label: {
                        Text("About")
                    }
                    Button("Quit") {
                        exit(0)
                    }
                }.padding()
            }
        }.onReceive(MonitorEngine.shared.$monitoredApps) { monitoredApps in
            items = monitoredApps
        }.onReceive(MonitorService.observerStatus) { attached in
            failedToSetupObservers = !attached
        }

    }
}
