//
//  WelcomeView.swift
//  NepTunes
//
//  Created by Adam Różyński on 16/07/2021.
//

import SwiftUI

struct WelcomeView: View {
    
    @StateObject private var model = PlayerViewModel(name: "tutorial")
    
    var body: some View {
        VStack(spacing: 10) {
            AVPlayerViewRepresented(player: model.player)
                .frame(height: 240)
            Text("A gem for music lovers")
                .font(.largeTitle)
            Text("NepTunes 2 Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.")
                .font(.body)
                .lineLimit(nil)
                .padding(.horizontal)
        }
        .onAppear {
            model.play()
        }
    }
}

struct WelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeView()
            .frame(width: 460)
    }
}
