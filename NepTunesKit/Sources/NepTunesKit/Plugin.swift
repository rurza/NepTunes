//
//  Plugin.swift
//  
//
//  Created by Adam Różyński on 28/05/2021.
//

import Foundation

public protocol Plugin {
    var name: String { get }
    var artworkData: Data { get }
    var playerObserver: PlayerObserver? { get }
    var playerController: PlayerController? { get }
}
