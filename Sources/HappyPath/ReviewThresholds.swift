//
//  ReviewThresholds.swift
//  HappyPath
//
//  Created by Tyler Reckart on 6/7/25.
//

import Foundation

/// A struct to define the thresholds for prompting a review.
/// These values can be customized by the app integrating `HappyPath`.
public struct ReviewThresholds {
    /// The minimum number of app launches before a review prompt can be considered.
    public let minLaunchesBeforePrompt: Int
    /// The minimum number of significant user actions before a review prompt can be considered.
    public let minSignificantActionsBeforePrompt: Int
    /// The minimum number of days since the app's first launch before an initial review prompt can be considered.
    public let minDaysSinceFirstLaunchBeforePrompt: Int
    /// The minimum number of days that must pass between consecutive review prompts.
    public let minDaysBetweenPrompts: Int

    /// Initializes a new set of review thresholds.
    /// - Parameters:
    ///   - minLaunchesBeforePrompt: Default is 5.
    ///   - minSignificantActionsBeforePrompt: Default is 3.
    ///   - minDaysSinceFirstLaunchBeforePrompt: Default is 7 (1 week).
    ///   - minDaysBetweenPrompts: Default is 90 (3 months), as recommended by Apple.
    public init(
        minLaunchesBeforePrompt: Int = 5,
        minSignificantActionsBeforePrompt: Int = 3,
        minDaysSinceFirstLaunchBeforePrompt: Int = 7,
        minDaysBetweenPrompts: Int = 90
    ) {
        self.minLaunchesBeforePrompt = minLaunchesBeforePrompt
        self.minSignificantActionsBeforePrompt = minSignificantActionsBeforePrompt
        self.minDaysSinceFirstLaunchBeforePrompt = minDaysSinceFirstLaunchBeforePrompt
        self.minDaysBetweenPrompts = minDaysBetweenPrompts
    }
}
