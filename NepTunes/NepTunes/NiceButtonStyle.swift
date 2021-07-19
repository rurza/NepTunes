//
//  NiceButtonStyle.swift
//  NepTunes
//
//  Created by Adam Różyński on 19/07/2021.
//

import Foundation
import SwiftUI

struct NiceButtonStyle: ButtonStyle {
    var foregroundColor: Color
    var pressedColor: Color

    @State private var hover = false
    @Environment(\.colorScheme) var currentScheme

    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .medium, design: .default))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .foregroundColor(foregroundColor)
            .background(hover ? Color(NSColor(white: currentScheme == .light ? 0 : 1, alpha: 0.05)) : .clear)
            .cornerRadius(8)
            .onHover(perform: { hovering in
                hover = hovering
            })
    }
}

extension View {
    func niceButton(
        foregroundColor: Color = .accentColor,
        pressedColor: Color = .gray
    ) -> some View {
        self.buttonStyle(
            NiceButtonStyle(
                foregroundColor: foregroundColor,
                pressedColor: pressedColor
            )
        )
    }
}
