# Pre-Deployment Checklist

Items requiring manual action outside the codebase before App Store submission.

## App Store Connect
- [ ] Create StoreKit product: `com.train.subscription.quarterly` — Pricing: £14.99/quarter, free trial: 7 days
- [ ] Verify `com.train.subscription.monthly` (£4.99) and `com.train.subscription.annual` (£59.99) are active and match paywall pricing
- [ ] Configure StoreKit offer codes in App Store Connect > Subscriptions > Offer Codes (for "Have a promo code?" on paywall)
- [ ] Update App Store screenshots to reflect new paywall, celebration overlay, and updated dashboard

## Xcode Project Settings
- [ ] Add `CoreSpotlight.framework` in Build Phases > Link Binary With Libraries
- [ ] Add `instagram-stories` to `LSApplicationQueriesSchemes` in Info.plist
- [ ] Verify Push Notifications capability is enabled in Signing & Capabilities
- [ ] Add `com.train.startWorkout` to `NSUserActivityTypes` in Info.plist (Siri Shortcuts)

## Hosted URLs (Required for Paywall)
- [ ] Host Terms of Service at a public URL (e.g. `https://train.app/terms`) — required by App Store Guidelines 3.1.1
- [ ] Host Privacy Policy at a public URL (e.g. `https://train.app/privacy`) — required by App Store Guidelines 5.1.1
- [ ] Update URL constants in `PaywallView.swift` when live

## External Service Credentials
- [ ] Strava API (future) — not needed for current share-sheet implementation; register at `strava.com/settings/api` if direct API integration added later
- [ ] Verify Bunny.net streaming credentials are production-ready

## Accessibility Compliance
- [ ] Run Xcode Accessibility Inspector on every screen after Phase 2
- [ ] Test Dynamic Type at all iOS text size settings (Settings > Accessibility > Display & Text Size > Larger Text)

## Pre-Submission Testing
- [ ] StoreKit sandbox: test all 3 subscription tiers, Restore Purchases, promo code redemption
- [ ] Instagram Stories share: test on physical device with Instagram installed
- [ ] Local notification: test rest timer notification with app backgrounded on physical device
