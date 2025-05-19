// HelperViews.swift
import SwiftUI

struct ParameterRow: View {
    let label: String
    let value: String?

    var body: some View {
        if let value = value, !value.isEmpty {
            HStack {
                Text("\(label):")
                    .font(.caption)
                    .foregroundColor(.gray)
                Text(value)
                    .font(.caption.weight(.medium))
                Spacer()
            }
        } else {
            EmptyView() // Don't show row if value is nil or empty
        }
    }
}

// You can add other small, reusable helper views here in the future
