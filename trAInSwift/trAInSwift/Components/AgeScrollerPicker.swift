//
//  AgeScrollerPicker.swift
//  trAInSwift
//
//  Scroller-style picker for age selection
//

import SwiftUI

struct AgeScrollerPicker: View {
    @Binding var age: Int
    let minAge: Int = 18
    let maxAge: Int = 100

    var body: some View {
        VStack(spacing: Spacing.xl) {
            // Display current age
            HStack(spacing: Spacing.sm) {
                Text("\(age)")
                    .font(.trainLargeNumber)
                    .foregroundColor(.trainPrimary)

                Text("years")
                    .font(.trainTitle)
                    .foregroundColor(.trainTextSecondary)
            }
            .frame(height: 80)

            // Picker
            Picker("Age", selection: $age) {
                ForEach(minAge...maxAge, id: \.self) { ageValue in
                    Text("\(ageValue)")
                        .font(.trainBody)
                        .tag(ageValue)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 150)
            .background(Color.white)
            .cornerRadius(CornerRadius.md)
        }
        .padding(.horizontal, Spacing.lg)
    }
}

#Preview {
    @Previewable @State var age: Int = 45

    VStack(spacing: 40) {
        AgeScrollerPicker(age: $age)

        Text("Selected age: \(age)")
            .font(.trainBody)
    }
    .padding()
    .background(Color.trainBackground)
}
