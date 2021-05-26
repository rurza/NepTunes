//
//  PluginsInterface.swift
//  Plugins
//
//  Created by Adam Różyński on 26/05/2021.
//

import Foundation

public protocol PluginsInterface {
    func trackDidChange(_ title: String, byArtist artist: String)
    init()
}
