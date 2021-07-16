//
//  ScrobblerReducerTests.swift
//  
//
//  Created by Adam Różyński on 16/07/2021.
//

import XCTest
import ComposableArchitecture
@testable import LastFmKit
@testable import LastFm
@testable import Shared

final class ScrobblerReducerTests: XCTestCase {
    
    func testReducer() throws {

        let date = Date()
        
        struct NoError: Error { }
        
        let track = Track(title: "Ágćtis Byrjun",
                          artist: "Sigur Rós",
                          album: "Heim",
                          albumArtist: "Sigur Rós",
                          artworkData: nil,
                          artworkURL: nil,
                          duration: 100)!

        // not interesting
        let lastFmClientMock = LastFm.LastFmUserClient { _, _ in
            Effect(error: NoError())
        } getAvatar: { _ in
            Effect(error: NoError())
        }
        
        
        let scrobblerClientMock = ScrobblerClient(scrobbleTrack: { track, sessionKey, date in
            typealias V = LastFmScrobbleTrackResponse.Correction
            let scrobbleResponse = LastFmScrobbleTrackResponse(artist: V(isCorrected: false, value: track.artist),
                                                               albumArtist: V(isCorrected: false, value: track.albumArtist ?? ""),
                                                               album: V(isCorrected: false, value: track.album ?? ""),
                                                               track: V(isCorrected: false, value: track.title),
                                                               scrobbleDate: date)
            
            return Effect(value: scrobbleResponse)
        },
        updateNowPlayingTrack: { _, _ in Effect(value: ()) },
        loveTrack: { _, _ in Effect(value: ()) },
        unloveTrack: { _, _ in Effect(value: ()) })
        
        
        let lastFmEnvironment = LastFmEnvironment(lastFmClient: lastFmClientMock, scrobblerClient: scrobblerClientMock)
        
        let settings = MockSettings()
        
        let environment = SystemEnvironment(localEnvironment: lastFmEnvironment,
                                            mainQueue: DispatchQueue.test.eraseToAnyScheduler(),
                                            runLoop: RunLoop.test.eraseToAnyScheduler(),
                                            date: { date },
                                            settings: settings)
        
        let testStore = TestStore(initialState: LastFmState(),
                                  reducer: lastFmTrackReducer,
                                  environment: environment)
        
        // 1. Love track
        // Nothing should happen
        testStore.send(.love(track))
        
        // 2. Unlove track
        // Nothing should happen
        testStore.send(.unlove(track))
        
        // 3. Scrobble
        // Nothing should happen but we should deal with it
        testStore.send(.scrobbleNow(track))
        
        // 4. Update now playing
        // Nothing should happen
        testStore.send(.updateNowPlaying(track))
    }
    
}
