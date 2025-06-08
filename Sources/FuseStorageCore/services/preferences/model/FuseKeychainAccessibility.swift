import Foundation

/// Enumeration defining Keychain accessibility levels for secure data storage
/// 
/// This enumeration provides different security levels for Keychain items,
/// controlling when the stored data can be accessed based on device lock state
/// and synchronization preferences across devices.
public enum FuseKeychainAccessibility {
    /// Data is accessible when the device is unlocked
    /// 
    /// Items with this accessibility are synchronized across devices and can be
    /// accessed whenever the device is unlocked by the user.
    case whenUnlocked
    
    /// Data is accessible after the first unlock since device boot
    /// 
    /// Items remain accessible until the device is restarted, even when locked.
    /// This provides a balance between security and convenience for background access.
    case afterFirstUnlock
    
    /// Data is accessible when unlocked, but only on this device
    /// 
    /// Similar to whenUnlocked but items are not synchronized to other devices,
    /// providing device-specific secure storage.
    case whenUnlockedThisDeviceOnly
    
    /// Data is accessible after first unlock, but only on this device
    /// 
    /// Combines the convenience of afterFirstUnlock with device-specific storage
    /// that doesn't synchronize across the user's devices.
    case afterFirstUnlockThisDeviceOnly
    
    /// Internal property mapping to Security framework constants
    var secValue: CFString {
        switch self {
        case .whenUnlocked: return kSecAttrAccessibleWhenUnlocked
        case .afterFirstUnlock: return kSecAttrAccessibleAfterFirstUnlock
        case .whenUnlockedThisDeviceOnly: return kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        case .afterFirstUnlockThisDeviceOnly: return kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        }
    }
}
