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
            Color.red
                .frame(maxHeight: 250)
            Text("A gem for music lovers")
                .font(.title)
            Text("NepTunes 2 is the best Apple Music and Spotify controller with built-in Last.fm scrobbler, editable hotkeys for common actions and beautiful themes.")
                .font(.callout)
                .lineLimit(nil)
                .padding()
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
