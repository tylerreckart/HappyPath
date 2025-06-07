//
//  HappyPath.swift
//  HappyPath
//
//  Created by Tyler Reckart on 6/7/25.
//

import Foundation
import StoreKit // Required for SKStoreReviewController to request app reviews.
import UIKit    // Required for UIWindowScene to present the review prompt in the active scene.

/// `ReviewManager` handles the logic for intelligently prompting users to review the app.
/// It uses `UserDefaults` to persist counts of app launches, significant user actions,
/// and the dates of review prompts to adhere to StoreKit's guidelines and improve user experience.
public class ReviewManager {
    /// The shared singleton instance of `ReviewManager`.
    public static let shared = ReviewManager()

    private let userDefaults: UserDefaults
    private let thresholds: ReviewThresholds

    /// Keys used for storing data in `UserDefaults`.
    private enum UserDefaultsKeys {
        static let appLaunchCount = "hp_appLaunchCount" // hp_ prefix each key to prevent conflicts.
        static let significantActionCount = "hp_significantActionCount"
        static let lastReviewRequestDate = "hp_lastReviewRequestDate"
        static let lastVersionPromptedForReview = "hp_lastVersionPromptedForReview"
        static let firstLaunchDate = "hp_firstLaunchDate"
    }

    /// Private initializer to enforce the singleton pattern.
    /// Allows for dependency injection of `UserDefaults` and `ReviewThresholds` for testing.
    /// - Parameters:
    ///   - userDefaults: The `UserDefaults` instance to use for persistence. Defaults to `.standard`.
    ///   - thresholds: The `ReviewThresholds` to use for determining when to prompt. Defaults to `ReviewThresholds()`.
    internal init(userDefaults: UserDefaults = .standard, thresholds: ReviewThresholds = ReviewThresholds()) {
        self.userDefaults = userDefaults
        self.thresholds = thresholds

        // Record the first launch date if it's not already set.
        // This is crucial for the `minDaysSinceFirstLaunchBeforePrompt` condition.
        if userDefaults.object(forKey: UserDefaultsKeys.firstLaunchDate) == nil {
            userDefaults.set(Date(), forKey: UserDefaultsKeys.firstLaunchDate)
            print("🚀 HappyPath: First launch date set.")
        }
    }

    /// Increments the count of app launches.
    /// This method should be called once per app launch, typically from your `AppDelegate`
    /// or the main `App` struct's `init` or `onAppear` of your root view.
    public func incrementAppLaunchCount() {
        let currentCount = userDefaults.integer(forKey: UserDefaultsKeys.appLaunchCount)
        userDefaults.set(currentCount + 1, forKey: UserDefaultsKeys.appLaunchCount)
        print("🚀 HappyPath: App launch count: \(currentCount + 1)")
    }

    /// Logs a significant user action within the app.
    /// This method should be called after a positive user interaction that indicates engagement,
    /// e.g., completing a task, viewing key content, or performing a successful operation.
    /// After logging, it immediately checks if a review prompt is appropriate.
    public func logSignificantAction() {
        let currentCount = userDefaults.integer(forKey: UserDefaultsKeys.significantActionCount)
        userDefaults.set(currentCount + 1, forKey: UserDefaultsKeys.significantActionCount)
        print("👍 HappyPath: Significant action count: \(currentCount + 1)")

        // After logging a significant action, check if we should prompt.
        requestReviewIfAppropriate()
    }

    /// Requests a review if appropriate when the app becomes active.
    /// This method should be called when the app transitions to the foreground or becomes active,
    /// perhaps after a slight delay to ensure the main UI is presented and the user isn't immediately interrupted.
    /// It primarily checks time-based and launch-based conditions.
    public func requestReviewOnAppActive() {
        let launchCount = userDefaults.integer(forKey: UserDefaultsKeys.appLaunchCount)
        guard launchCount >= thresholds.minLaunchesBeforePrompt else {
            print("🌟 HappyPath: Not prompting (launch count \(launchCount) < \(thresholds.minLaunchesBeforePrompt)).")
            return
        }

        if let firstLaunch = userDefaults.object(forKey: UserDefaultsKeys.firstLaunchDate) as? Date {
            let daysSinceFirstLaunch = Calendar.current.dateComponents([.day], from: firstLaunch, to: Date()).day ?? 0
            guard daysSinceFirstLaunch >= thresholds.minDaysSinceFirstLaunchBeforePrompt else {
                print("🌟 HappyPath: Not prompting (days since first launch \(daysSinceFirstLaunch) < \(thresholds.minDaysSinceFirstLaunchBeforePrompt)).")
                return
            }
        }
        
        // If initial conditions are met, proceed to the comprehensive check.
        requestReviewIfAppropriate()
    }

    /// Evaluates all conditions to determine if a review prompt should be displayed.
    /// This is the core logic for the review prompting.
    internal func requestReviewIfAppropriate() {
        let currentVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Unknown"
        let lastPromptedVersion = userDefaults.string(forKey: UserDefaultsKeys.lastVersionPromptedForReview)
        
        // Condition 1: Time since last prompt. Apple recommends not prompting too frequently.
        if let lastRequestDate = userDefaults.object(forKey: UserDefaultsKeys.lastReviewRequestDate) as? Date {
            let daysSinceLastPrompt = Calendar.current.dateComponents([.day], from: lastRequestDate, to: Date()).day ?? 0
            guard daysSinceLastPrompt >= thresholds.minDaysBetweenPrompts else {
                print("🌟 HappyPath: Not prompting (last prompt was \(daysSinceLastPrompt) days ago, less than \(thresholds.minDaysBetweenPrompts) days).")
                return
            }
        }
        
        // Condition 2: App launch count.
        let launchCount = userDefaults.integer(forKey: UserDefaultsKeys.appLaunchCount)
        guard launchCount >= thresholds.minLaunchesBeforePrompt else {
            print("🌟 HappyPath: Not prompting (launch count \(launchCount) < \(thresholds.minLaunchesBeforePrompt)).")
            return
        }

        // Condition 3: Significant action count.
        let actionCount = userDefaults.integer(forKey: UserDefaultsKeys.significantActionCount)
        guard actionCount >= thresholds.minSignificantActionsBeforePrompt else {
            print("🌟 HappyPath: Not prompting (significant actions \(actionCount) < \(thresholds.minSignificantActionsBeforePrompt)).")
            return
        }
        
        // Condition 4: Time since first launch. This condition is primarily for the *initial* prompt.
        // It ensures the user has had enough time with the app to form an opinion.
        if lastPromptedVersion == nil || lastPromptedVersion != currentVersion {
            // Only apply this threshold if it's the first prompt for *any* version
            // or if it's a new app version and we haven't prompted for it yet.
            if let firstLaunch = userDefaults.object(forKey: UserDefaultsKeys.firstLaunchDate) as? Date {
                let daysSinceFirstLaunch = Calendar.current.dateComponents([.day], from: firstLaunch, to: Date()).day ?? 0
                guard daysSinceFirstLaunch >= thresholds.minDaysSinceFirstLaunchBeforePrompt else {
                    print("🌟 HappyPath: Not prompting (days since first launch \(daysSinceFirstLaunch) < \(thresholds.minDaysSinceFirstLaunchBeforePrompt) for initial prompt).")
                    return
                }
            }
        }

        print("🌟 HappyPath: All conditions met. Requesting review.")
        
        // Request the review on the main thread.
        DispatchQueue.main.async {
            guard let windowScene = UIApplication.shared.connectedScenes
                .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene else {
                print("❌ HappyPath: Could not find active window scene to request review.")
                return
            }
            SKStoreReviewController.requestReview(in: windowScene)
            
            // Update UserDefaults after successfully requesting a review.
            self.userDefaults.set(Date(), forKey: UserDefaultsKeys.lastReviewRequestDate)
            self.userDefaults.set(currentVersion, forKey: UserDefaultsKeys.lastVersionPromptedForReview)
            print("🌟 HappyPath: Review requested. Last prompt date and version updated.")
        }
    }

    /// Resets all review prompt counters in `UserDefaults`.
    /// This method is primarily for development and testing purposes.
    /// **Do not use in production builds unless specifically for user-initiated reset functions.**
    public func resetReviewPromptCounters() {
        userDefaults.removeObject(forKey: UserDefaultsKeys.appLaunchCount)
        userDefaults.removeObject(forKey: UserDefaultsKeys.significantActionCount)
        userDefaults.removeObject(forKey: UserDefaultsKeys.lastReviewRequestDate)
        userDefaults.removeObject(forKey: UserDefaultsKeys.lastVersionPromptedForReview)
        userDefaults.removeObject(forKey: UserDefaultsKeys.firstLaunchDate)
        print("⚠️ HappyPath: All review counters reset.")
    }
}
