//
//  PlayerController.swift
//  
//
//  Created by Adam Różyński on 28/05/2021.
//

import Foundation

public protocol PlayerController {
    func playStop()
    func nextTrack()
    func backTrack()
    func changeVolume(_ newVolume: Int)
    func loveTrack()
    func unLoveTrack()
}
