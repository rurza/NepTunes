//
//  ContentView.swift
//  NepTunes
//
//  Created by Adam Różyński on 28/04/2021.
//

import SwiftUI
import ComposableArchitecture
import Player

struct ContentView: View {
    
    let store: Store<PlayerState, PlayerAction>
    
    var body: some View {
        WithViewStore(store) { viewStore in
            HStack {
                Image(nsImage: NSImage(data: viewStore.currentPlayerState?.currentTrack?.artworkData ?? Data()) ?? NSImage(systemSymbolName: "music.mic", accessibilityDescription: "artwork")!).resizable().frame(width: 200, height: 200)
                VStack {
                    Text(viewStore.currentPlayerState?.currentTrack?.title ?? "None").bold()
                    Text(viewStore.currentPlayerState?.currentTrack?.artist ?? "None")
                }
            }
        }
        .frame(width: 500, height: 500)
    }
}

