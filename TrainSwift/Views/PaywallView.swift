//
//  PaywallView.swift
//  TrainSwift
//
//  Production paywall with 3 subscription tiers and StoreKit 2 integration
//

import SwiftUI
import StoreKit

// MARK: - Product Identifiers

private enum SubscriptionProduct: String, CaseIterable {
    case monthly = "com.train.subscription.monthly"
    case quarterly = "com.train.subscription.quarterly"
    case annual = "com.train.subscription.annual"

    /// Display order: Monthly | Annual | Quarterly (left to right)
    static var displayOrder: [SubscriptionProduct] {
        [.monthly, .annual, .quarterly]
    }
}

// MARK: - PaywallView

struct PaywallView: View {
    let onComplete: () -> Void

    @State private var products: [Product] = []
    @State private var selectedProductID: String = SubscriptionProduct.monthly.rawValue
    @State private var isLoading = true
    @State private var purchaseInProgress = false
    @State private var errorMessage: String?
    @State private var showCards: Bool = false

    var body: some View {
        ZStack {
            if isLoading {
                ProgressView("Loading subscriptions...")
                    .foregroundColor(.trainTextPrimary)
            } else {
                mainContent
            }

            if purchaseInProgress {
                purchaseOverlay
            }
        }
        .charcoalGradientBackground()
        .task {
            await loadProducts()
        }
    }

    // MARK: - Main Content

    private var mainContent: some View {
        VStack(spacing: 0) {
            // Top bar: Dismiss + Restore
            topBar
                .padding(.horizontal, Spacing.md)
                .padding(.top, Spacing.sm)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: Spacing.lg) {
                    // Header
                    headerSection
                        .padding(.top, Spacing.xl)

                    // Pricing tiers
                    pricingTiersSection
                        .padding(.horizontal, Spacing.md)

                    // Error message
                    if let error = errorMessage {
                        Text(error)
                            .font(.trainCaption)
                            .foregroundColor(.trainError)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, Spacing.lg)
                    }

                    // Continue CTA
                    continueButton
                        .padding(.horizontal, Spacing.lg)

                    // Promo code link
                    promoCodeLink

                    // Legal links
                    legalLinks
                        .padding(.bottom, Spacing.xl)
                }
            }
        }
        .disabled(purchaseInProgress)
        .opacity(purchaseInProgress ? 0.6 : 1.0)
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            Button {
                AppLogger.logUI("[PAYWALL] Dismissed")
                onComplete()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.trainTextSecondary)
                    .frame(width: ElementHeight.touchTarget, height: ElementHeight.touchTarget)
            }

            Spacer()

            Button {
                Task {
                    await restorePurchases()
                }
            } label: {
                Text("Restore")
                    .font(.trainCaption)
                    .foregroundColor(.trainTextSecondary)
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: Spacing.sm) {
            ZStack {
                Circle()
                    .fill(Color.trainPrimary.opacity(0.2))
                    .frame(width: 80, height: 80)

                Image(systemName: "dumbbell.fill")
                    .font(.system(size: IconSize.xl))
                    .foregroundColor(.trainPrimary)
            }

            Text("Unlock Your Full Potential")
                .font(.trainTitle)
                .foregroundColor(.trainTextPrimary)
                .multilineTextAlignment(.center)

            Text("Train with structure, guidance and\nprogress in mind.")
                .font(.trainBody)
                .foregroundColor(.trainTextSecondary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Pricing Tiers

    private var pricingTiersSection: some View {
        HStack(spacing: Spacing.sm) {
            ForEach(Array(SubscriptionProduct.displayOrder.enumerated()), id: \.element.rawValue) { index, tier in
                let product = products.first { $0.id == tier.rawValue }
                PricingTierCard(
                    tier: tier,
                    product: product,
                    isSelected: selectedProductID == tier.rawValue,
                    onSelect: {
                        withAnimation(.easeInOut(duration: AnimationDuration.quick)) {
                            selectedProductID = tier.rawValue
                        }
                    }
                )
                .offset(y: showCards ? 0 : 30)
                .opacity(showCards ? 1 : 0)
                .animation(.easeOut(duration: 0.4).delay(Double(index) * 0.1), value: showCards)
            }
        }
        .onAppear {
            showCards = true
        }
    }

    // MARK: - Continue Button

    private var continueButton: some View {
        Button {
            guard let product = products.first(where: { $0.id == selectedProductID }) else {
                AppLogger.logUI("[PAYWALL] No product found for ID: \(selectedProductID)", level: .warning)
                // Fallback: allow proceeding without purchase for testing
                onComplete()
                return
            }
            Task {
                await purchase(product)
            }
        } label: {
            Text("CONTINUE")
                .font(.trainBodyMedium)
                .fontWeight(.bold)
                .foregroundColor(.trainTextOnPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: ButtonHeight.standard)
                .background(Color.trainPrimary)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.pill, style: .continuous))
                .shadowStyle(.elevated)
        }
    }

    // MARK: - Promo Code

    private var promoCodeLink: some View {
        Button {
            presentPromoCodeSheet()
        } label: {
            Text("Have a promo code?")
                .font(.trainCaption)
                .foregroundColor(.trainTextSecondary)
                .underline()
        }
    }

    // MARK: - Legal Links

    private var legalLinks: some View {
        HStack(spacing: Spacing.md) {
            Link("Terms of Service", destination: URL(string: "https://train.app/terms")!)
                .font(.trainCaptionSmall)
                .foregroundColor(.trainTextSecondary)

            Text("|")
                .font(.trainCaptionSmall)
                .foregroundColor(.trainTextSecondary.opacity(0.5))

            Link("Privacy Policy", destination: URL(string: "https://train.app/privacy")!)
                .font(.trainCaptionSmall)
                .foregroundColor(.trainTextSecondary)
        }
    }

    // MARK: - Purchase Overlay

    private var purchaseOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: Spacing.md) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)

                Text("Processing...")
                    .font(.trainBody)
                    .foregroundColor(.white)
            }
            .padding(Spacing.xl)
            .background(Color.trainPrimary)
            .cornerRadius(CornerRadius.md)
        }
    }

    // MARK: - StoreKit Logic

    private func loadProducts() async {
        do {
            let productIDs = SubscriptionProduct.allCases.map(\.rawValue)
            let loadedProducts = try await Product.products(for: productIDs)
            products = loadedProducts
            isLoading = false
            AppLogger.logUI("[PAYWALL] Loaded \(products.count) subscription products")
        } catch {
            AppLogger.logUI("[PAYWALL] Failed to load products: \(error)", level: .error)
            errorMessage = String(localized: "Unable to load subscriptions. Please try again.")
            isLoading = false
        }
    }

    private func purchase(_ product: Product) async {
        purchaseInProgress = true
        errorMessage = nil

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    AppLogger.logUI("[PAYWALL] Purchase successful: \(transaction.productID)")
                    await transaction.finish()
                    await MainActor.run {
                        purchaseInProgress = false
                        onComplete()
                    }

                case .unverified(_, let error):
                    AppLogger.logUI("[PAYWALL] Transaction unverified: \(error)", level: .error)
                    await MainActor.run {
                        errorMessage = String(localized: "Purchase verification failed")
                        purchaseInProgress = false
                    }
                }

            case .pending:
                AppLogger.logUI("[PAYWALL] Purchase pending")
                await MainActor.run {
                    errorMessage = String(localized: "Purchase is pending approval")
                    purchaseInProgress = false
                }

            case .userCancelled:
                AppLogger.logUI("[PAYWALL] User cancelled purchase")
                await MainActor.run {
                    purchaseInProgress = false
                }

            @unknown default:
                await MainActor.run {
                    purchaseInProgress = false
                }
            }
        } catch {
            AppLogger.logUI("[PAYWALL] Purchase failed: \(error)", level: .error)
            await MainActor.run {
                errorMessage = String(localized: "Purchase failed: \(error.localizedDescription)")
                purchaseInProgress = false
            }
        }
    }

    private func restorePurchases() async {
        purchaseInProgress = true
        errorMessage = nil

        do {
            try await AppStore.sync()
            AppLogger.logUI("[PAYWALL] Restore purchases completed")

            // Check if any current entitlements exist after sync
            var hasActiveSubscription = false
            for await result in Transaction.currentEntitlements {
                if case .verified = result {
                    hasActiveSubscription = true
                    break
                }
            }

            await MainActor.run {
                purchaseInProgress = false
                if hasActiveSubscription {
                    AppLogger.logUI("[PAYWALL] Active subscription found after restore")
                    onComplete()
                } else {
                    errorMessage = String(localized: "No active subscriptions found")
                }
            }
        } catch {
            AppLogger.logUI("[PAYWALL] Restore failed: \(error)", level: .error)
            await MainActor.run {
                errorMessage = String(localized: "Restore failed: \(error.localizedDescription)")
                purchaseInProgress = false
            }
        }
    }

    private func presentPromoCodeSheet() {
        #if !targetEnvironment(simulator)
        if #available(iOS 16.0, *) {
            // On iOS 16+, use the modern offer code redemption
            // This is handled by the system via subscription store
        }
        // Fallback to SKPaymentQueue for promo code redemption
        SKPaymentQueue.default().presentCodeRedemptionSheet()
        AppLogger.logUI("[PAYWALL] Presenting promo code redemption sheet")
        #else
        AppLogger.logUI("[PAYWALL] Promo code redemption not available in simulator", level: .warning)
        #endif
    }
}

// MARK: - Pricing Tier Card

private struct PricingTierCard: View {
    let tier: SubscriptionProduct
    let product: Product?
    let isSelected: Bool
    let onSelect: () -> Void

    private var tierTitle: String {
        switch tier {
        case .monthly: return "1 Month"
        case .quarterly: return "3 Months"
        case .annual: return "1 Year"
        }
    }

    private var badgeText: String? {
        switch tier {
        case .monthly: return "Most popular"
        case .annual: return "Best value"
        case .quarterly: return nil
        }
    }

    private var badgeColor: Color {
        switch tier {
        case .monthly: return .trainPrimary
        case .annual: return .trainSuccess
        case .quarterly: return .clear
        }
    }

    private var displayPrice: String {
        if let product {
            return product.displayPrice
        }
        // Fallback prices
        switch tier {
        case .monthly: return "£4.99"
        case .quarterly: return "£14.99"
        case .annual: return "£59.99"
        }
    }

    private var periodLabel: String {
        switch tier {
        case .monthly: return "/month"
        case .quarterly: return "/quarter"
        case .annual: return "/year"
        }
    }

    private var perWeekPrice: String {
        if let product {
            let weeklyPrice: Decimal
            switch tier {
            case .monthly: weeklyPrice = product.price / 4
            case .quarterly: weeklyPrice = product.price / 13
            case .annual: weeklyPrice = product.price / 52
            }
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.locale = product.priceFormatStyle.locale
            formatter.maximumFractionDigits = 2
            return formatter.string(from: weeklyPrice as NSDecimalNumber) ?? ""
        }
        // Fallback per-week prices
        switch tier {
        case .monthly: return "£1.25"
        case .quarterly: return "£1.15"
        case .annual: return "£1.15"
        }
    }

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: Spacing.sm) {
                // Badge area (fixed height so cards align)
                if let badge = badgeText {
                    Text(badge)
                        .font(.trainTag)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, Spacing.xs)
                        .background(badgeColor)
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm, style: .continuous))
                } else {
                    // Spacer to keep alignment consistent
                    Text(" ")
                        .font(.trainTag)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, Spacing.xs)
                        .opacity(0)
                }

                // Tier title
                Text(tierTitle)
                    .font(.trainHeadline)
                    .foregroundColor(.trainTextPrimary)

                // Price
                VStack(spacing: Spacing.xxs) {
                    Text(displayPrice)
                        .font(.trainBodyMedium)
                        .foregroundColor(.trainTextPrimary)

                    Text(periodLabel)
                        .font(.trainCaptionSmall)
                        .foregroundColor(.trainTextSecondary)
                }

                // Per-week breakdown
                Text("\(perWeekPrice)/wk")
                    .font(.trainCaptionSmall)
                    .foregroundColor(.trainTextSecondary)
                    .padding(.top, Spacing.xs)
            }
            .padding(.vertical, Spacing.md)
            .padding(.horizontal, Spacing.sm)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous)
                    .strokeBorder(
                        isSelected ? Color.trainPrimary : Color.trainBorderSubtle,
                        lineWidth: isSelected ? BorderWidth.emphasis : BorderWidth.hairline
                    )
            )
            .shadowStyle(isSelected ? .card : .subtle)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    PaywallView(onComplete: {
        AppLogger.logUI("Paywall completed!")
    })
}
