//
//  PlayerObserver.swift
//  
//
//  Created by Adam Różyński on 28/05/2021.
//

import Foundation

public protocol PlayerObserver {
    func trackDidChange(title: String, byArtist: String, album: String, albumArtist: String?, duration: Double, artworkData: Data?)
    func currentPlayerDidChange(newPlayer: String)
    func playerDidStopPlayback(player: String)
    func playerDidPausePlayback(player: String)
    func playerDidChangeVolume(_ newVolume: Int)
    func trackDiDChangeLoveStatus(title: String, byArtist: String, loved: Bool)
}
