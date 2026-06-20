import Foundation

enum AppInfo {
    static let displayName: String =
        Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ?? "Current"
    static let version: String =
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.1.0"
    static let bundleIdentifier: String =
        Bundle.main.bundleIdentifier ?? "com.richardknop.current"
}
