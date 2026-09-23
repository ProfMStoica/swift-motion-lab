import SwiftUI

/// The app's entry point: a single window showing the  main `ContentView`.
@main
public struct SwiftMotionLabApp: App {
    public init() {}

    public var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
