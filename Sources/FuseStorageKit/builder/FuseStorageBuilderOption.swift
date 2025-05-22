import Foundation

public protocol FuseStorageBuilderOption {
    var query: FuseStorageOptionQuery { get }
    func build() throws -> FuseManageable
}

public protocol FuseStorageOptionQuery {
    var name: String { get }
}
