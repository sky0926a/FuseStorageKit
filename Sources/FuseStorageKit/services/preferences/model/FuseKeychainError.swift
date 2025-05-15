import Foundation
import Security

/// Enumeration of Keychain-specific errors that can occur during secure storage operations
/// 
/// This error type provides specific error cases for Keychain operations, helping
/// developers identify and handle different types of secure storage failures
/// with appropriate error handling and user feedback.
public enum FuseKeychainError: Error {
    /// An unhandled Keychain operation error occurred
    /// 
    /// This error wraps the underlying OSStatus error code from Security framework
    /// operations, providing access to the specific system error for debugging.
    /// - Parameter status: The OSStatus error code from the failed Keychain operation
    case unhandledError(status: OSStatus)
    
    /// Data encoding failed during Keychain storage preparation
    /// 
    /// This error occurs when the data cannot be properly encoded for storage
    /// in the Keychain, typically due to serialization issues with complex types.
    case encodingError
}
