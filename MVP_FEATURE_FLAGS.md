# MVP Feature Flags

This document tracks feature flags for the MVP/TestFlight release vs Production release.

## Paywall Feature Flag

**Location**: [ProgramReadyView.swift:20](trAInSwift/Views/ProgramReadyView.swift#L20)

```swift
private let skipPaywallForMVP = true  // 👈 Change this for production
```

### Current Setting (MVP/TestFlight)

```swift
private let skipPaywallForMVP = true
```

**Behavior:**
- Users complete the questionnaire
- Users create account
- Shows "Creating your account..." loading screen
- **SKIPS PAYWALL** ✅
- Goes directly to Dashboard with their program

**Flow:**
```
Questionnaire → Program Ready → Signup → Loading → Dashboard
                                                   ↑
                                        Paywall SKIPPED
```

### Production Setting

```swift
private let skipPaywallForMVP = false
```

**Behavior:**
- Users complete the questionnaire
- Users create account
- Shows "Creating your account..." loading screen
- **SHOWS PAYWALL** (StoreKit subscription)
- After successful subscription, goes to Dashboard

**Flow:**
```
Questionnaire → Program Ready → Signup → Loading → Paywall → Dashboard
```

## How to Switch for Production

When ready to launch production version with subscriptions:

1. Open [ProgramReadyView.swift](trAInSwift/Views/ProgramReadyView.swift)
2. Find line 20: `private let skipPaywallForMVP = true`
3. Change to: `private let skipPaywallForMVP = false`
4. Ensure you have valid StoreKit product IDs configured in [PaywallView.swift](trAInSwift/Views/PaywallView.swift)

## StoreKit Configuration (for Production)

**Location**: [PaywallView.swift:163-166](trAInSwift/Views/PaywallView.swift#L163-L166)

```swift
let productIDs = [
    "com.train.subscription.annual",    // Replace with your App Store Connect product ID
    "com.train.subscription.monthly"    // Replace with your App Store Connect product ID
]
```

### Before Going to Production:

1. ✅ Create products in App Store Connect
2. ✅ Update product IDs in PaywallView.swift
3. ✅ Test subscriptions in sandbox environment
4. ✅ Set `skipPaywallForMVP = false` in ProgramReadyView.swift
5. ✅ Test full flow with real subscription

## Why This Works

The program is saved **immediately after signup** (in [PostQuestionnaireSignupView.swift:195-198](trAInSwift/Views/PostQuestionnaireSignupView.swift#L195-L198)), so:

✅ **MVP users**: Get their program without paying
✅ **Production users**: Get their program saved before paywall (no data loss if they cancel)
✅ **Both flows**: Work correctly because program save happens early

## Testing

### Test MVP Flow (Current)
1. Complete questionnaire
2. Create account with email/password
3. Should see "Creating your account..." for 2 seconds
4. Should go **directly to Dashboard** with program
5. **Should NOT see paywall**

### Test Production Flow (Future)
1. Set `skipPaywallForMVP = false`
2. Complete questionnaire
3. Create account with email/password
4. Should see "Creating your account..." for 2 seconds
5. **Should see PaywallView** with subscription options
6. Can test with StoreKit sandbox account

## Console Logs

Look for these logs to verify which flow is running:

**MVP Mode:**
```
🚀 MVP Mode: Skipping paywall
✅ Onboarding flow complete - user authenticated with program
```

**Production Mode:**
```
✅ Loaded 2 subscription products
🛒 Product card tapped: Annual Plan
✅ Purchase successful: com.train.subscription.annual
```

## Notes

- All paywall code is preserved and ready for production
- No code needs to be deleted or rewritten
- Just flip one boolean flag to enable subscriptions
- Program save logic works for both MVP and Production

## Related Files

- [ProgramReadyView.swift](trAInSwift/Views/ProgramReadyView.swift) - Contains feature flag
- [PaywallView.swift](trAInSwift/Views/PaywallView.swift) - Full StoreKit implementation
- [PostQuestionnaireSignupView.swift](trAInSwift/Views/PostQuestionnaireSignupView.swift) - Saves program immediately
- [AccountCreationLoadingView.swift](trAInSwift/Views/AccountCreationLoadingView.swift) - 2-second loading animation
- [ContentView.swift](trAInSwift/ContentView.swift) - Main app coordinator
