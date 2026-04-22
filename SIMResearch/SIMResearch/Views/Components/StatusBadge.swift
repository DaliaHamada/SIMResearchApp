//
//  StatusBadge.swift
//  SIMResearch
//

import SwiftUI

struct StatusBadge: View {
    let text: String
    let systemImage: String
    let tint: Color

    var body: some View {
        Label(text, systemImage: systemImage)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule().fill(tint.opacity(0.15))
            )
            .foregroundStyle(tint)
    }
}
