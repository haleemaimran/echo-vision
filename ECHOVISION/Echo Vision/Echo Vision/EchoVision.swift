//
//  ENTRY FROM HERE

//import SwiftUI
//
//@main
//struct Echo_VisionApp: App {
//    var body: some Scene {
//        WindowGroup {
//            ContentView()
//        }
//    }
//}

import SwiftUI

@main
struct EchoVisionApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                ContentView()
            } else {
                OnboardingView()
            }
        }
    }
}

#Preview{
    ContentView()
}
