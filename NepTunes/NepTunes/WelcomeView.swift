//
//  WelcomeView.swift
//  NepTunes
//
//  Created by Adam Różyński on 16/07/2021.
//

import SwiftUI
import AVKit

struct WelcomeView: View {
    
    @StateObject private var model = PlayerViewModel(name: "tutorial")
    
    var body: some View {
        VStack {
            AVPlayerViewRepresented(player: model.player)
                .frame(height: 240)
            VStack(spacing: 20) {
                Text("Welcome in NepTunes 2")
                    .font(.title)
                Text("NepTunes 2 is the best Apple Music and Spotify controller with built-in Last.fm scrobbler, editable hotkeys for common actions and beautiful themes.")
                    .font(.callout)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding()
        }
        .frame(minWidth: 460)
        .ignoresSafeArea(.container, edges: .top)
        .onAppear {
            model.play()
        }
    }
}

struct WelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeView()
    }
}
