import Foundation

/// Builder class for creating and configuring FuseStorageKit instances
public class FuseStorageBuilder {
    private var database: [FuseDatabaseBuilderOption] = []
    private var preferences: [FusePreferencesBuilderOption] = []
    private var file: [FuseFileBuilderOption] = []
    private var sync: [FuseSyncBuilderOption] = []

    /// Initialize a new builder with default configurations
    public init() {}

    /// Configure the database manager
    /// - Parameter databaseManager: The database manager implementation to use
    /// - Returns: Self for method chaining
    public func with(database: FuseDatabaseBuilderOption) -> Self {
        self.database.append(database)
        return self
    }

    /// Configure the preferences manager
    /// - Parameter preferencesManager: The preferences manager implementation to use
    /// - Returns: Self for method chaining
    public func with(preferences: FusePreferencesBuilderOption) -> Self {
        self.preferences.append(preferences)
        return self
    }

    /// Configure the file manager
    /// - Parameter fileManager: The file manager implementation to use
    /// - Returns: Self for method chaining
    public func with(file: FuseFileBuilderOption) -> Self {
        self.file.append(file)
        return self
    }

    /// Configure the synchronization manager
    /// - Parameter syncManager: The sync manager implementation to use
    /// - Returns: Self for method chaining
    public func with(sync: FuseSyncBuilderOption) -> Self {
        self.sync.append(sync)
        return self
    }

    /// Build a FuseStorageKit instance with the configured components
    /// - Returns: A fully configured FuseStorageKit instance
    /// - Throws: Errors during component initialization
    public func build() throws -> FuseStorage {
        let databaseManagers = try buildManagers(
            from: database,
            default: [.sqlite()],
            extractName: { $0.query.name },
            buildCast: { try $0.build() as? FuseDatabaseManageable }
        )

        let preferencesManagers = try buildManagers(
            from: preferences,
            default: [.userDefaults()],
            extractName: { $0.query.name },
            buildCast: { try $0.build() as? FusePreferencesManageable }
        )

        let fileManagers = try buildManagers(
            from: file,
            default: [.document()],
            extractName: { $0.query.name },
            buildCast: { try $0.build() as? FuseFileManageable }
        )

        let syncManagers = try buildManagers(
            from: sync,
            default: [.noSync()],
            extractName: { $0.query.name },
            buildCast: { try $0.build() as? FuseSyncManageable }
        )

        return FuseStorage(databaseManagers: databaseManagers,
                           preferencesManagers: preferencesManagers,
                           fileManagers: fileManagers,
                           syncManagers: syncManagers
        )
    }

    func buildManagers<Queryable, Manageable>(from items: [Queryable],
                                              default defaultItems: [Queryable],
                                              extractName: (Queryable) -> String,
                                              buildCast: (Queryable) throws -> Manageable?) rethrows -> [String: Manageable] {
        let list = items.isEmpty ? defaultItems : items
        return try list.reduce(into: [:]) { dict, item in
            if let manager = try buildCast(item) {
                dict[extractName(item)] = manager
            }
        }
    }
}
