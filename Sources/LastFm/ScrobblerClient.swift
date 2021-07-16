//
//  ScrobblerClient.swift
//  
//
//  Created by Adam Różyński on 15/07/2021.
//

import Foundation
import Shared
import LastFmKit
import ComposableArchitecture

typealias SessionKey = String

struct ScrobblerClient {
    let scrobbleTrack: (Track, SessionKey, Date) -> Effect<LastFmScrobbleTrackResponse, Error>
    let updateNowPlayingTrack: (Track, SessionKey) -> Effect<Void, Error>
    let loveTrack: (Track, SessionKey) -> Effect<Void, Error>
    let unloveTrack: (Track, SessionKey) -> Effect<Void, Error>
}

extension ScrobblerClient {
    static let live: Self = {
        let lastFmClient = LastFmClient(secret: Secrets.lastFmApiSecret, apiKey: Secrets.lastFmApiKey)
        return Self(
            scrobbleTrack: { track, sessionKey, date in
                lastFmClient.scrobbleTrack(track.title,
                                           byArtist: track.artist,
                                           albumArtist: track.albumArtist,
                                           album: track.album,
                                           scrobbleDate: date,
                                           sessionKey: sessionKey)
                    .eraseToEffect()
            },
            updateNowPlayingTrack: { track, sessionKey in
                lastFmClient
                    .updateNowPlayingForTrack(track.title,
                                              byArtist: track.artist,
                                              album: track.album,
                                              sessionKey: sessionKey)
                    .eraseToEffect()
            },
            loveTrack: { track, sessionKey in
                lastFmClient.loveTrack(track.title, byArtist: track.artist, sessionKey: sessionKey).eraseToEffect()
            },
            unloveTrack: { track, sessionKey in
                lastFmClient.unloveTrack(track.title, byArtist: track.artist, sessionKey: sessionKey).eraseToEffect()
            })
    }()
}
