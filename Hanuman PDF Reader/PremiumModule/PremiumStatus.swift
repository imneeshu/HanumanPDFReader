import Foundation

/// A global singleton utility for accessing premium purchase status from UserDefaults.
public final class PremiumStatus {
    /// Shared singleton instance
    public static let shared = PremiumStatus()
    private init() {}

    /// Returns true if any premium plan (monthly, yearly, or one-time) is active.
    public var isPremiumPurchased: Bool {
        let defaults = UserDefaults.standard
        let monthly = defaults.bool(forKey: "monthlySubscribed")
        let yearly = defaults.bool(forKey: "yearlySubscribed")
        let oneTime = defaults.bool(forKey: "oneTimePurchase")
        return monthly || yearly || oneTime
    }

    /// Returns the status of each premium plan individually.
    public var details: (monthly: Bool, yearly: Bool, oneTime: Bool) {
        let defaults = UserDefaults.standard
        return (
            monthly: defaults.bool(forKey: "monthlySubscribed"),
            yearly: defaults.bool(forKey: "yearlySubscribed"),
            oneTime: defaults.bool(forKey: "oneTimePurchase")
        )
    }
}
