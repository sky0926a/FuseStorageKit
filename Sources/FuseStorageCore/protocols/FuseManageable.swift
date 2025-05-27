import Foundation

/// Base protocol for all storage managers in FuseStorageKit
/// 
/// This protocol serves as a marker interface that all storage managers must conform to.
/// It provides a common type that can be used for dependency injection and manager
/// registration within the FuseStorage facade, ensuring type safety and consistency
/// across different storage implementations.
public protocol FuseManageable {
}