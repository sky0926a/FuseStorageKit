import Foundation

#if os(iOS) || os(tvOS) || os(watchOS)
import UIKit
/// Cross-platform image type alias for iOS, tvOS, and watchOS platforms
/// 
/// This typealias provides a unified interface for image handling across different
/// Apple platforms, mapping to UIImage on iOS/tvOS/watchOS for consistent API usage.
public typealias FuseImage = UIImage
#elseif os(macOS)
import AppKit
/// Cross-platform image type alias for macOS platform
/// 
/// This typealias provides a unified interface for image handling across different
/// Apple platforms, mapping to NSImage on macOS for consistent API usage.
public typealias FuseImage = NSImage
#endif
