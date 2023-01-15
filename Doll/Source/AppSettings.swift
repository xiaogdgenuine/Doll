
class AppSettings {
    @UserDefaultSetting("SETTINGS_Hide_When_App_Not_Running")
    static var hideWhenAppNotRunning = false

    @UserDefaultSetting("SETTINGS_Hide_When_Nothing_Coming")
    static var hideWhenNothingComing = false

    @UserDefaultSetting("SETTINGS_SHOW_ALERT_IN_FULL_SCREEN_Mode")
    static var showAlertInFullScreenMode = true

    @UserDefaultSetting("SETTINGS_Show_As_Red_Badge")
    static var showAsRedBadge = false

    @UserDefaultSetting("SETTINGS_Show_Only_App_Icon")
    static var showOnlyAppIcon = false

    @UserDefaultSetting("SETTINGS_Giant_Badge_Enabled_Apps")
    static var giantBadgeConfigs: [String: Bool] = [:]

    static func toggleGiantBadge(for appName: String, value: Bool) {
        AppSettings.giantBadgeConfigs[appName] = value
    }

    static func isGiantBadgeEnabled(for appName: String) -> Bool {
        AppSettings.giantBadgeConfigs[appName] ?? false
    }
}
