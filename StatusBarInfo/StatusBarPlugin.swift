//
//  StatusBarPlugin.swift
//  StatusBarInfo
//
//  Created by Adam Różyński on 26/05/2021.
//

import Plugins
import AppKit

class StatusBarPlugin: PluginsInterface {
    
    lazy var statusBar = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

    required init() {
        
    }
    
    func trackDidChange(_ title: String, byArtist artist: String) {
        statusBar.button?.title = "\(artist) – \(title)"
    }
    
    
}
