import Foundation

/// Protocol defining the contract for storage component builder options
/// 
/// This protocol establishes the interface that all storage component builders must implement.
/// It provides a standardized way to create and configure different types of storage managers
/// within the FuseStorageKit framework.
public protocol FuseStorageBuilderOption {
    /// The unique identifier name for this builder option
    /// 
    /// This name is used as a key for caching manager instances and should be unique
    /// within the scope of the same manager type to prevent conflicts.
    var name: String { get }
    
    /// Creates and configures a storage manager instance
    /// 
    /// This method is responsible for instantiating and setting up the specific storage
    /// manager based on the configuration provided by the implementing builder option.
    /// 
    /// - Returns: A configured storage manager instance conforming to FuseManageable
    /// - Throws: Configuration or initialization errors during manager creation
    func build() throws -> FuseManageable
}