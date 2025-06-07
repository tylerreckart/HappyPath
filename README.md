# 🌟 HappyPath Reviews
HappyPath is a lightweight Swift Package designed to intelligently prompt users for app reviews at optimal times, aiming for a better user experience and higher quality ratings. It follows Apple's guidelines by ensuring review prompts are not excessive or disruptive, based on configurable thresholds for app launches, significant user actions, and time elapsed.

## Features
- **Intelligent Prompting:** HappyPath goes beyond simple launch counts. It prompts for reviews by evaluating a combination of factors: the number of app launches, the frequency of significant user actions, and the overall duration of app usage.
- **Configurable Thresholds:** Every app has unique user engagement patterns. HappyPath allows you to easily customize the exact conditions that trigger a review prompt. You can define the minimum number of launches, significant actions, and days since first use, as well as the minimum interval between prompts.
- **StoreKit Integration:** HappyPath directly leverages Apple's native SKStoreReviewController to provide a seamless and familiar in-app review experience.
- **Version-Aware:** To prevent user fatigue and maintain a positive relationship, HappyPath intelligently tracks the app version for which a review has already been requested. This ensures that users are not repeatedly asked to review the same version of your application, respecting Apple's recommendations and enhancing user satisfaction.
- **Singleton Pattern:** The ReviewManager is implemented as a singleton, providing a single, globally accessible instance.

## Requirements
- iOS 13.0+
- macOS 10.15+
- tvOS 13.0+
- watchOS 6.0+
- Xcode 11.0+
- Swift 5.1+

## Installation
You can add HappyPath to your project using Swift Package Manager.

In Xcode, open your project.

Navigate to File > Add Packages...

In the search bar, enter the GitHub repository URL:
https://github.com/tylerreckart/HappyPath.git

Select HappyPath and choose your preferred dependency rule (e.g., "Up to Next Major Version").

Click Add Package.

## Usage
Using HappyPath involves a few simple steps in your application's lifecycle and at points of significant user engagement.

### Initialization _(Optional: Custom Thresholds)_
The ReviewManager uses default thresholds, but you can customize them during initialization if needed.

```swift
import HappyPath
import SwiftUI

@main
struct MyApp: App {
    init() {
        // Example: Customize thresholds if default values don't suit your app
        let customThresholds = ReviewThresholds(
            minLaunchesBeforePrompt: 10, // Prompt after 10 launches
            minSignificantActionsBeforePrompt: 5, // Prompt after 5 significant actions
            minDaysSinceFirstLaunchBeforePrompt: 14, // Prompt after 2 weeks of use
            minDaysBetweenPrompts: 180 // Prompt every 6 months
        )
        // Initialize ReviewManager with custom thresholds
        _ = ReviewManager(thresholds: customThresholds)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

If you don't need custom thresholds, simply access the shared instance:

```swift
import HappyPath
import SwiftUI

@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```


### Incrementing App Launch Count
Call `incrementAppLaunchCount()` once every time your app launches. A good place for this is within your App struct's onAppear for its main WindowGroup or in your AppDelegate.

```swift
import SwiftUI
import HappyPath

struct ContentView: View {
    var body: some View {
        Text("Welcome to my app!")
            .onAppear {
                ReviewManager.shared.incrementAppLaunchCount()
            }
    }
}
```

### Requesting Review on App Active
You should also call `requestReviewOnAppActive()` when your app becomes active. This method will check for the minimum launch count and days since first launch before considering a review prompt. This is a good place to trigger a potential prompt without interrupting the user's flow too early.

```swift
import SwiftUI
import HappyPath

struct ContentView: View {
    // ...
    var body: some View {
        Text("Your content here")
            .onAppear {
                ReviewManager.shared.incrementAppLaunchCount()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                // Delaying slightly to ensure UI is ready and not immediately interrupted
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    ReviewManager.shared.requestReviewOnAppActive()
                }
            }
    }
}
```


### Logging Significant Actions
Call `logSignificantAction()` whenever a user performs an action that indicates they are engaged with your app and likely having a positive experience. This could be completing a task, saving data, or using a key feature.

```swift
import SwiftUI
import HappyPath

struct SettingsView: View {
    var body: some View {
        Form {
            Button("Save Settings") {
                // Perform settings save logic
                ReviewManager.shared.logSignificantAction() // Log a significant action
            }
            Button("Share Content") {
                // Perform share logic
                ReviewManager.shared.logSignificantAction() // Another significant action
            }
        }
    }
}
```

### Resetting Counters _(Development/Testing Only)_
For testing purposes, you can reset all review counters:

```swift
import HappyPath

// In your development/debug menu or test suite
ReviewManager.shared.resetReviewPromptCounters()
```

**Note: Do not use `resetReviewPromptCounters()` in production builds unless it's part of a very specific user-initiated "reset app data" feature.**

## Contributing
Contributions are welcome! If you find a bug or have an idea for an enhancement, please open an issue or submit a pull request on GitHub.

## License
This project is open-source and available under the MIT License. See the LICENSE file for more details.
