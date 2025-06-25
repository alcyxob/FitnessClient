// Can be in its own file HelperViews.swift or at the bottom of LoginView.swift

import SwiftUI

struct DividerText: View {
    let label: String
    let horizontalPadding: CGFloat
    let color: Color

    init(label: String = "OR", horizontalPadding: CGFloat = 8, color: Color = .secondary) {
        self.label = label
        self.horizontalPadding = horizontalPadding
        self.color = color
    }

    var body: some View {
        HStack {
            line
            Text(label)
                .foregroundColor(color)
                .font(.caption) // Make it a bit smaller
                .fontWeight(.medium)
                .padding(.horizontal, horizontalPadding)
            line
        }
        .padding(.vertical, 10) // Add some vertical spacing around it
    }

    var line: some View {
        VStack {
            Divider().background(color.opacity(0.5)) // Make divider a bit subtle
        }
    }
}

// Optional: Preview for DividerText itself
struct DividerText_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            DividerText()
            DividerText(label: "AND", color: .blue)
            DividerText(label: "CONTINUE WITH", horizontalPadding: 15, color: .green)
        }
        .padding()
    }
}
