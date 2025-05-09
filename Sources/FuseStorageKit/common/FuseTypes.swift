import Foundation

#if os(iOS) || os(tvOS) || os(watchOS)
import UIKit
/// 統一的圖像類型，在 iOS/tvOS/watchOS 平台使用 UIImage
public typealias FuseImage = UIImage
#elseif os(macOS)
import AppKit
/// 統一的圖像類型，在 macOS 平台使用 NSImage
public typealias FuseImage = NSImage
#endif
