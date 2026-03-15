import SwiftUI
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        return true
    }
}

@main
struct ForceSubApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @State private var authViewModel: AuthViewModel

    init() {
        FirebaseApp.configure()
        _authViewModel = State(initialValue: AuthViewModel())

        // Debug: verify Info.plist privacy keys are present in the bundle
        let bundle = Bundle.main
        if let cameraDesc = bundle.object(forInfoDictionaryKey: "NSCameraUsageDescription") as? String {
            print("✅ NSCameraUsageDescription: \(cameraDesc)")
        } else {
            print("❌ NSCameraUsageDescription is MISSING from Info.plist!")
        }
        if let micDesc = bundle.object(forInfoDictionaryKey: "NSMicrophoneUsageDescription") as? String {
            print("✅ NSMicrophoneUsageDescription: \(micDesc)")
        } else {
            print("❌ NSMicrophoneUsageDescription is MISSING from Info.plist!")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(authViewModel)
        }
    }
}
