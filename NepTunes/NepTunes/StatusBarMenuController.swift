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
        //
        //
        let preferencesMenuItem = NSMenuItem(title: "Preferences", action: nil, keyEquivalent: ",")
        preferencesMenuItem.target = self
        //
        //
        menu.addItem(preferencesMenuItem)
        //
        //
        menu.addItem(NSMenuItem.separator())
        let quitMenuItem = NSMenuItem(title: "Quit NepTunes", action: #selector(NSApp.terminate), keyEquivalent: "q")
        quitMenuItem.allowsKeyEquivalentWhenHidden = true
        menu.addItem(quitMenuItem)
        //
        //
        return menu
    }
    
    @objc func openPreferences() {
        
    }
    

    
}
