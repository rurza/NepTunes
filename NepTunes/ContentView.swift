//
//  ContentView.swift
//  NepTunes
//
//  Created by Adam Różyński on 28/04/2021.
//

import SwiftUI
import ComposableArchitecture

struct ContentView: View {
    
    let store: Store<PlayerState, PlayerAction>
    
    var body: some View {
        WithViewStore(store) { viewStore in
            HStack {
                Image(nsImage: NSImage(data: viewStore.currentPlayerState.currentTrack?.coverData ?? Data()) ?? NSImage(systemSymbolName: "music.mic", accessibilityDescription: "artwork")!).resizable().frame(width: 200, height: 200)
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
    static var previews: some View {
        ContentView(store: Store(
            initialState: PlayerState(),
            reducer: playerReducer,
            environment: PlayerEnvironment(newPlayerLaunched: .none,
                                           playerQuit: .none,
                                           musicTrackDidChange: .none,
                                           musicApp: MusicApp())
        ))
    }
}

//extension NSImage {
//    convenience init?(data: Data?) {
//        if let data = data {
//            self.init(data: data)
//        }
//        return nil
//    }
//}
