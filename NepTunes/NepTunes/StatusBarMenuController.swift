//
//  StatusBarMenuController.swift
//  NepTunes
//
//  Created by Adam Różyński on 19/07/2021.
//

import Cocoa
import ComposableArchitecture
import AppCore

class StatusBarMenuController: NSObject {
    
    private let viewStore: ViewStore<AppState, AppAction>
    
    init(viewStore: ViewStore<AppState, AppAction>) {
        self.viewStore = viewStore
    }
    
    func menu() -> NSMenu {
        let menu = NSMenu()
        
        let preferencesMenuItem = NSMenuItem(title: "Preferences", action: #selector(openPreferences), keyEquivalent: ",")
        preferencesMenuItem.target = self
//        menu.autoenablesItems = false
        menu.addItem(preferencesMenuItem)
        return menu
    }
    
    @objc func openPreferences() {
        
    }
    

    
}
