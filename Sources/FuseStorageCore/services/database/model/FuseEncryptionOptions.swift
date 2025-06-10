import Foundation

/// Configuration options for database encryption using SQLCipher
/// 
/// This structure provides a fluent interface for configuring database encryption
/// settings including passphrase, page size, key derivation parameters, and memory
/// security options. It supports both custom configuration and preset security levels.
public struct EncryptionOptions: Sendable {
    // MARK: - Properties
    public private(set) var passphrase: String
    public private(set) var pageSize: Int?
    public private(set) var kdfIter: Int?
    public private(set) var memorySecurity: Bool?
    public private(set) var defaultKdfIter: Int?
    public private(set) var defaultPageSize: Int?

    // MARK: - Initializer
    /// Initializes encryption options with a passphrase
    /// - Parameter passphrase: The encryption key to use
    public init(_ passphrase: String) {
        self.passphrase = passphrase
        self.pageSize = nil
        self.kdfIter = nil
        self.memorySecurity = nil
        self.defaultKdfIter = nil
        self.defaultPageSize = nil
    }
    
    /// Private initializer for creating configured instances
    private init(
        passphrase: String,
        pageSize: Int?,
        kdfIter: Int?,
        memorySecurity: Bool?,
        defaultKdfIter: Int?,
        defaultPageSize: Int?
    ) {
        self.passphrase = passphrase
        self.pageSize = pageSize
        self.kdfIter = kdfIter
        self.memorySecurity = memorySecurity
        self.defaultKdfIter = defaultKdfIter
        self.defaultPageSize = defaultPageSize
    }

    /// Sets the page size for the encrypted database
    /// - Parameter value: Page size (typical values: 1024, 2048, 4096)
    /// - Returns: Updated EncryptionOptions
    @discardableResult
    public func pageSize(_ value: Int) -> Self {
        var copy = self
        copy.pageSize = value
        return copy
    }

    /// Sets the KDF iteration count for the encryption
    /// - Parameter value: Number of iterations (higher = more secure but slower)
    /// - Returns: Updated EncryptionOptions
    @discardableResult
    public func kdfIter(_ value: Int) -> Self {
        var copy = self
        copy.kdfIter = value
        return copy
    }

    /// Enables or disables memory security
    /// - Parameter value: Whether to enable memory security
    /// - Returns: Updated EncryptionOptions
    @discardableResult
    public func memorySecurity(_ value: Bool) -> Self {
        var copy = self
        copy.memorySecurity = value
        return copy
    }

    /// Sets the default KDF iteration count for new databases
    /// - Parameter value: Default number of iterations
    /// - Returns: Updated EncryptionOptions
    @discardableResult
    public func defaultKdfIter(_ value: Int) -> Self {
        var copy = self
        copy.defaultKdfIter = value
        return copy
    }

    /// Sets the default page size for new databases
    /// - Parameter value: Default page size
    /// - Returns: Updated EncryptionOptions
    @discardableResult
    public func defaultPageSize(_ value: Int) -> Self {
        var copy = self
        copy.defaultPageSize = value
        return copy
    }
}

extension EncryptionOptions {
    // MARK: - Preset configurations
    /// Standard: balanced security and performance.
    ///
    /// - passphrase: required user-provided key.
    /// - pageSize: 4096 (aligns with system page size for optimal I/O).
    /// - kdfIter: 64_000 (moderate key derivation cost to resist brute-force while keeping open times reasonable).
    /// - memorySecurity: true (zeroizes sensitive memory buffers upon release).
    /// - defaultKdfIter: 64_000 (applied on new database creation).
    /// - defaultPageSize: 4096 (applied on new database creation).
    public static func standard(passphrase: String) -> EncryptionOptions {
        return EncryptionOptions(passphrase)
            .pageSize(4096)
            .kdfIter(64_000)
            .memorySecurity(true)
            .defaultKdfIter(64_000)
            .defaultPageSize(4096)
    }

    /// High: maximum security with increased CPU cost when opening the database.
    ///
    /// - passphrase: required user-provided key.
    /// - pageSize: 4096 (aligns with system page size).
    /// - kdfIter: 200_000 (high key derivation cost for stronger brute-force resistance).
    /// - memorySecurity: true (ensures sensitive data is zeroized in memory).
    /// - defaultKdfIter: 200_000 (applied on new database creation).
    /// - defaultPageSize: 4096 (applied on new database creation).
    public static func high(passphrase: String) -> EncryptionOptions {
        return EncryptionOptions(passphrase)
            .pageSize(4096)
            .kdfIter(200_000)
            .memorySecurity(true)
            .defaultKdfIter(200_000)
            .defaultPageSize(4096)
    }

    /// Performance: reduced CPU overhead with moderate security trade-off.
    ///
    /// - passphrase: required user-provided key.
    /// - pageSize: 4096 (aligns with system page size for consistency).
    /// - kdfIter: 10_000 (lower derivation cost to speed up database open operations).
    /// - memorySecurity: false (skips zeroization to save CPU cycles).
    /// - defaultKdfIter: 10_000 (applied on new database creation).
    /// - defaultPageSize: 4096 (applied on new database creation).
    public static func performance(passphrase: String) -> EncryptionOptions {
        return EncryptionOptions(passphrase)
            .pageSize(4096)
            .kdfIter(10_000)
            .memorySecurity(false)
            .defaultKdfIter(10_000)
            .defaultPageSize(4096)
    }
}
