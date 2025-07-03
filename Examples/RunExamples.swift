import FuseStorageKit
import Foundation

// Example runner - demonstrates all FuseStorageKit features
func runAllExamples() {
    print("🚀 FuseStorageKit Examples")
    print("=" * 50)
    
    // 1. Basic usage example
    print("\n1️⃣ Basic Usage Example")
    print("-" * 30)
    do {
        try exampleUsage()
    } catch {
        print("❌ Basic example failed: \(error)")
    }
    
    // 2. Note app example
    print("\n2️⃣ Note App Example")
    print("-" * 30)
    do {
        try noteAppExample()
    } catch {
        print("❌ Note app example failed: \(error)")
    }
    
    // 3. Preferences example
    print("\n3️⃣ Preferences Example")
    print("-" * 30)
    do {
        try preferencesExample()
    } catch {
        print("❌ Preferences example failed: \(error)")
    }
    
    // 4. File management example
    print("\n4️⃣ File Management Example")
    print("-" * 30)
    do {
        try fileManagerExample()
    } catch {
        print("❌ File management example failed: \(error)")
    }
    
    print("\n✅ All examples completed!")
    print("=" * 50)
}

// Individual example functions (add these to your app)
extension String {
    static func *(lhs: String, rhs: Int) -> String {
        return String(repeating: lhs, count: rhs)
    }
}

// Uncomment to run examples
// runAllExamples() 