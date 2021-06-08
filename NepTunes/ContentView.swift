//
//  ContentView.swift
//  NepTunes
//
//  Created by Adam Różyński on 28/04/2021.
//

import SwiftUI
import ComposableArchitecture

struct ContentView: View {
    
    let store: Store<SharedState<PlayerState>, PlayerAction>
    
    var body: some View {
        WithViewStore(store) { viewStore in
            HStack {
                Image(nsImage: NSImage(data: viewStore.currentPlayerState.currentTrack?.artworkData ?? Data()) ?? NSImage(systemSymbolName: "music.mic", accessibilityDescription: "artwork")!).resizable().frame(width: 200, height: 200)
                VStack {
                    Text(viewStore.currentPlayerState.currentTrack?.title ?? "None").bold()
                    Text(viewStore.currentPlayerState.currentTrack?.artist ?? "None")
                }
            }
        }
        .frame(width: 500, height: 500)
    }
}


struct ContentView_Previews: PreviewProvider {
    
    static var musicApp: MusicApp {
        MusicApp()
    }
    
    static var previews: some View {
        ContentView(store: Store(
            initialState: SharedState(settings: Settings(), state: PlayerState()),
            reducer: playerReducer,
            environment: .live(environment: PlayerEnvironment(newPlayerLaunched: .none,
                                                              playerQuit: .none,
                                                              musicTrackDidChange: .none,
                                                              musicApp: musicApp,
                                                              getTrackInfo: getTrackCoverFromPlayer(musicApp),
                                                              artworkDownloader: .live))
        ))
    }
}
