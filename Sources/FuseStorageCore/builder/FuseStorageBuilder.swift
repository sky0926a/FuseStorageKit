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
    /// - Parameter database: The database builder option to configure and add
    /// - Returns: Self for method chaining
    public func with(database: FuseDatabaseBuilderOption) -> Self {
        self.database.append(database)
        return self
    }

    /// Configure the preferences manager
    /// - Parameter preferences: The preferences builder option to configure and add
    /// - Returns: Self for method chaining
    public func with(preferences: FusePreferencesBuilderOption) -> Self {
        self.preferences.append(preferences)
        return self
    }

    /// Configure the file manager
    /// - Parameter file: The file builder option to configure and add
    /// - Returns: Self for method chaining
    public func with(file: FuseFileBuilderOption) -> Self {
        self.file.append(file)
        return self
    }

    /// Configure the synchronization manager
    /// - Parameter sync: The sync builder option to configure and add
    /// - Returns: Self for method chaining
    public func with(sync: FuseSyncBuilderOption) -> Self {
        self.sync.append(sync)
        return self
    }

    /// Build a FuseStorage instance with all configured storage components
    /// 
    /// This method creates a fully configured FuseStorage instance by building all the
    /// registered storage managers (database, preferences, file, and sync) and organizing
    /// them into dictionaries keyed by their names for efficient lookup and management.
    /// 
    /// - Returns: A fully configured FuseStorage instance ready for use
    /// - Throws: Configuration or initialization errors during component creation
    public func build() throws -> FuseStorage {
        let databaseManagers = try buildManagers(
            from: database,
            ofType: FuseDatabaseManageable.self
        )

        let preferencesManagers = try buildManagers(
            from: preferences,
            ofType: FusePreferencesManageable.self
        )

        let fileManagers = try buildManagers(
            from: file,
            ofType: FuseFileManageable.self
        )

        let syncManagers = try buildManagers(
            from: sync,
            ofType: FuseSyncManageable.self
        )

        return FuseStorage(databaseManagers: databaseManagers,
                           preferencesManagers: preferencesManagers,
                           fileManagers: fileManagers,
                           syncManagers: syncManagers
        )
    }

    private func buildManagers<T>(from items: [FuseStorageBuilderOption], ofType type: T.Type) throws -> [String: T] {
        var dict = [String:T]()
        for option in items {
            if let m = try option.build() as? T {
                dict[option.name] = m
            }
        }
        return dict
    }
}
