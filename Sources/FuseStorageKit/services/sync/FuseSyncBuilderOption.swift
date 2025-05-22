import Foundation

public enum FuseSyncBuilderOptionType {
    #if canImport(FirebaseStorage)
    case firebase
    #endif
    case noSync
    case custom(name: String, sync: FuseSyncManageable)
}

public struct FuseSyncBuilderOption: FuseStorageBuilderOption {
    
    private let optionType: FuseSyncBuilderOptionType

    init(optionType: FuseSyncBuilderOptionType) {
        self.optionType = optionType
    }

    #if canImport(FirebaseStorage)
    public static func firebase() -> Self {
        return .init(optionType: .firebase)
    }
    #endif

    public static func noSync() -> Self {
        return .init(optionType: .noSync)
    }

    public static func custom(name: String, sync: FuseSyncManageable) -> Self {
        return .init(optionType: .custom(name: name, sync: sync))
    }

    public func build() throws ->  FuseManageable {
        switch self.optionType {
        #if canImport(FirebaseStorage)
        case .firebase:
            return FuseFirebaseSyncManager()
        #endif
        case .noSync:
            return NoSyncManager()
        case .custom(_, let sync):
            return sync
        }
    }

    public var query: FuseStorageOptionQuery {
        switch self.optionType {
        #if canImport(FirebaseStorage)
        case .firebase:
            return FuseSyncOptionQuery.firebase
        #endif
        case .noSync:
            return FuseSyncOptionQuery.noSync
        case .custom(let name, _):
            return FuseSyncOptionQuery.custom(name)
        }
    }
}

public enum FuseSyncOptionQuery: FuseStorageOptionQuery {
    #if canImport(FirebaseStorage)
    case firebase
    #endif
    case noSync
    case custom(_ name: String)

    public var name: String {
        switch self {
        #if canImport(FirebaseStorage)
        case .firebase:
            return "sync_firebase"
        #endif
        case .noSync:
            return "sync_noSync"
        case .custom(let name):
            return "sync_custom_\(name)"
        }
    }
}
