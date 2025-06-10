@_exported import FuseStorageCore
internal import FuseObjcBridge

// MARK: - C-callable Swift function for auto registration
@_cdecl("fuseRegisterFactory")
public func fuseRegisterFactory() {
    let factory = FuseGRDBDatabaseFactory()
    FuseDatabaseFactoryRegistry.shared.setMainFactory(factory)
}
