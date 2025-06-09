import FuseStorageKit
import Foundation

// Example app settings
struct AppSettings: Codable {
    let theme: String
    let fontSize: Int
    let language: String
    let notifications: Bool
}

// Usage example: App preferences and secure storage
func preferencesExample() throws {
    // 1. Build storage with both UserDefaults and Keychain
    let storage = try FuseStorageBuilder()
        .with(preferences: .userDefaults())
        .with(preferences: .keychain("com.myapp.secure"))
        .build()
    
    let userDefaults = storage.pref(.userDefaults())!
    let keychain = storage.pref(.keychain("com.myapp.secure"))!
    
    // 2. Store general app settings in UserDefaults
    let settings = AppSettings(
        theme: "dark",
        fontSize: 14,
        language: "en",
        notifications: true
    )
    
    try userDefaults.set(settings, forKey: "appSettings")
    try userDefaults.set("2024-01-01", forKey: "lastLaunchDate")
    try userDefaults.set(42, forKey: "launchCount")
    print("✅ Saved app settings to UserDefaults")
    
    // 3. Store sensitive data in Keychain
    try keychain.set("user_token_12345", forKey: "authToken")
    try keychain.set("secret_api_key", forKey: "apiKey")
    try keychain.set("user@example.com", forKey: "userEmail")
    print("🔒 Saved sensitive data to Keychain")
    
    // 4. Retrieve from UserDefaults
    let savedSettings: AppSettings? = userDefaults.get(forKey: "appSettings")
    let lastLaunch: String? = userDefaults.get(forKey: "lastLaunchDate")
    let launchCount: Int? = userDefaults.get(forKey: "launchCount")
    
    print("📱 Retrieved settings:")
    print("  Theme: \(savedSettings?.theme ?? "default")")
    print("  Font size: \(savedSettings?.fontSize ?? 12)")
    print("  Last launch: \(lastLaunch ?? "never")")
    print("  Launch count: \(launchCount ?? 0)")
    
    // 5. Retrieve from Keychain
    let token: String? = keychain.get(forKey: "authToken")
    let apiKey: String? = keychain.get(forKey: "apiKey")
    let email: String? = keychain.get(forKey: "userEmail")
    
    print("🔑 Retrieved secure data:")
    print("  Has auth token: \(token != nil)")
    print("  Has API key: \(apiKey != nil)")
    print("  User email: \(email ?? "none")")
    
    // 6. Check existence
    let hasSettings = userDefaults.containsValue(forKey: "appSettings")
    let isLoggedIn = keychain.containsValue(forKey: "authToken")
    
    print("📊 Status:")
    print("  Has settings: \(hasSettings)")
    print("  Is logged in: \(isLoggedIn)")
    
    // 7. Update settings
    let updatedSettings = AppSettings(
        theme: "light",
        fontSize: 16,
        language: "zh",
        notifications: false
    )
    try userDefaults.set(updatedSettings, forKey: "appSettings")
    print("✏️ Updated app settings")
    
    // 8. Remove values
    userDefaults.removeValue(forKey: "lastLaunchDate")
    keychain.removeValue(forKey: "authToken")
    print("🗑️ Removed some values")
    
    // 9. Verify removal
    let hasToken = keychain.containsValue(forKey: "authToken")
    let hasLastLaunch = userDefaults.containsValue(forKey: "lastLaunchDate")
    
    print("🔍 After removal:")
    print("  Has token: \(hasToken)")
    print("  Has last launch: \(hasLastLaunch)")
    
    print("Preferences example completed successfully!")
} 