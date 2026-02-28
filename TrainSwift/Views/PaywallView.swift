//
//  PaywallView.swift
//  TrainSwift
//
//  Paywall screen with REAL Apple StoreKit 2 subscriptions
//

import SwiftUI
import StoreKit

struct PaywallView: View {
    let onComplete: () -> Void

    @State private var products: [Product] = []
    @State private var isLoading = true
    @State private var purchaseInProgress = false
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            if isLoading {
                ProgressView("Loading subscriptions...")
                    .foregroundColor(.trainTextPrimary)
            } else {
                VStack(spacing: Spacing.xl) {
                    Spacer()

                    // Logo/Icon
                    ZStack {
                        Circle()
                            .fill(Color.trainPrimary.opacity(0.2))
                            .frame(width: 100, height: 100)

                        Image(systemName: "dumbbell.fill")
                            .font(.system(size: IconSize.xl))
                            .foregroundColor(.trainPrimary)
                    }

                    // Header
                    VStack(spacing: Spacing.sm) {
                        Text("Free 7 Day Trial")
                            .font(.trainTitle)
                            .foregroundColor(.trainTextPrimary)

                        Text("Cancel anytime.")
                            .font(.trainSubtitle)
                            .foregroundColor(.trainTextSecondary)

                        Text("Train with structure, guidance and\nprogress in mind.")
                            .font(.trainBody)
                            .foregroundColor(.trainTextPrimary)
                            .multilineTextAlignment(.center)
                            .padding(.top, Spacing.sm)
                    }

                    // Subscription Options from StoreKit
                    if !products.isEmpty {
                        VStack(spacing: Spacing.md) {
                            ForEach(products, id: \.id) { product in
                                ProductCard(
                                    product: product,
                                    isMostPopular: product.subscription?.subscriptionPeriod.unit == .year,
                                    onPurchase: {
                                        Task {
                                            await purchase(product)
                                        }
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, Spacing.lg)
                    } else {
                        // Fallback static display if no products loaded
                        VStack(spacing: Spacing.md) {
                            SubscriptionCard(
                                title: "Annual Plan",
                                price: "£8.33/mo",
                                description: "7 days free, then £99.99/year",
                                isMostPopular: true
                            )

                            SubscriptionCard(
                                title: "Monthly Plan",
                                price: "£13.99/mo",
                                description: "7 days free.",
                                isMostPopular: false
                            )
                        }
                        .padding(.horizontal, Spacing.lg)
                    }

                    // Error message
                    if let error = errorMessage {
                        Text(error)
                            .font(.trainCaption)
                            .foregroundColor(.red)
                            .padding(.horizontal, Spacing.lg)
                    }

                    Spacer()

                    // Start Trial Button (or skip for testing)
                    VStack(spacing: Spacing.sm) {
                        if !products.isEmpty {
                            Text("Tap a plan above to subscribe")
                                .font(.trainCaption)
                                .foregroundColor(.trainTextSecondary)
                        } else {
                            Button(action: {
                                AppLogger.logUI("[PAYWALL] No products loaded - proceeding anyway for testing", level: .warning)
                                onComplete()
                            }) {
                                Text("Continue (No Products)")
                                    .font(.trainBodyMedium)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: ButtonHeight.standard)
                                    .background(Color.trainPrimary)
                                    .cornerRadius(CornerRadius.md)
                            }
                            .padding(.horizontal, Spacing.lg)
                        }
                    }
                    .padding(.bottom, Spacing.xl)
                }
                .disabled(purchaseInProgress)
                .opacity(purchaseInProgress ? 0.6 : 1.0)
            }

            // Purchase in progress overlay
            if purchaseInProgress {
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
        }
        .charcoalGradientBackground()
        .task {
            await loadProducts()
        }
    }

    // Load products from StoreKit
    private func loadProducts() async {
        do {
            // Replace with your actual product IDs from App Store Connect
            let productIDs = [
                "com.train.subscription.annual",
                "com.train.subscription.monthly"
            ]

            let loadedProducts = try await Product.products(for: productIDs)
            products = loadedProducts.sorted { p1, p2 in
                // Sort annual first
                (p1.subscription?.subscriptionPeriod.unit == .year) &&
                (p2.subscription?.subscriptionPeriod.unit != .year)
            }
            isLoading = false
            AppLogger.logUI("[PAYWALL] Loaded \(products.count) subscription products")
        } catch {
            AppLogger.logUI("[PAYWALL] Failed to load products: \(error)", level: .error)
            errorMessage = String(localized: "Unable to load subscriptions. Please try again.")
            isLoading = false
        }
    }

    // Purchase a product
    private func purchase(_ product: Product) async {
        purchaseInProgress = true
        errorMessage = nil

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                // Verify the transaction
                switch verification {
                case .verified(let transaction):
                    // Transaction is verified - grant access
                    AppLogger.logUI("[PAYWALL] Purchase successful: \(transaction.productID)")
                    await transaction.finish()

                    // Complete onboarding
                    await MainActor.run {
                        purchaseInProgress = false
                        onComplete()
                    }

                case .unverified(_, let error):
                    // Transaction failed verification
                    AppLogger.logUI("[PAYWALL] Transaction unverified: \(error)", level: .error)
                    await MainActor.run {
                        errorMessage = String(localized: "Purchase verification failed")
                        purchaseInProgress = false
                    }
                }

            case .pending:
                // Purchase is pending (e.g., requires parental approval)
                AppLogger.logUI("[PAYWALL] Purchase pending")
                await MainActor.run {
                    errorMessage = String(localized: "Purchase is pending approval")
                    purchaseInProgress = false
                }

            case .userCancelled:
                // User cancelled the purchase
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
}

// Product Card for StoreKit products
struct ProductCard: View {
    let product: Product
    let isMostPopular: Bool
    let onPurchase: () -> Void

    var body: some View {
        Button(action: {
            AppLogger.logUI("[PAYWALL] Product card tapped: \(product.displayName)")
            onPurchase()
        }) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                if isMostPopular {
                    HStack {
                        Spacer()
                        Text("Most Popular")
                            .font(.trainCaption)
                            .fontWeight(.bold)
                            .foregroundColor(.trainPrimary)
                            .padding(.horizontal, Spacing.sm)
                            .padding(.vertical, Spacing.xs)
                            .background(Color.trainPrimary.opacity(0.1))
                            .cornerRadius(CornerRadius.sm)
                        Spacer()
                    }
                }

                HStack {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text(product.displayName)
                            .font(.trainHeadline)
                            .foregroundColor(.trainTextPrimary)

                        Text(product.description)
                            .font(.trainCaption)
                            .foregroundColor(.trainTextSecondary)
                    }

                    Spacer()

                    Text(product.displayPrice)
                        .font(.trainBodyMedium)
                        .foregroundColor(.trainPrimary)
                }
            }
            .padding(Spacing.md)
            .appCard()
            .cornerRadius(CornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .stroke(isMostPopular ? Color.trainPrimary : Color.clear, lineWidth: isMostPopular ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// Static subscription card (fallback)
struct SubscriptionCard: View {
    let title: String
    let price: String
    let description: String
    let isMostPopular: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            if isMostPopular {
                HStack {
                    Spacer()
                    Text("Most Popular")
                        .font(.trainCaption)
                        .fontWeight(.bold)
                        .foregroundColor(.trainPrimary)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, Spacing.xs)
                        .background(Color.trainPrimary.opacity(0.1))
                        .cornerRadius(CornerRadius.sm)
                    Spacer()
                }
            }

            HStack {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(title)
                        .font(.trainHeadline)
                        .foregroundColor(.trainTextPrimary)

                    Text(description)
                        .font(.trainCaption)
                        .foregroundColor(.trainTextSecondary)
                }

                Spacer()

                Text(price)
                    .font(.trainBodyMedium)
                    .foregroundColor(.trainPrimary)
            }
        }
        .padding(Spacing.md)
        .appCard()
        .cornerRadius(CornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .stroke(isMostPopular ? Color.trainPrimary : Color.clear, lineWidth: isMostPopular ? 2 : 1)
        )
    }
}

#Preview {
    PaywallView(onComplete: {
        AppLogger.logUI("Paywall completed!")
    })
}
