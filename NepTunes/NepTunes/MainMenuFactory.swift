//
//  MainMenuFactory.swift
//  NepTunes
//
//  Created by Adam Różyński on 19/07/2021.
//

import Cocoa

struct MainMenuFactory {
    static func mainMenu() -> NSMenu {
        let mainMenu = NSMenu()
        let appMenuItem = NSMenuItem(title: "NepTunes", action: nil, keyEquivalent: "")
        let appMenu = NSMenu()

        mainMenu.addItem(appMenuItem)
        appMenuItem.submenu = appMenu
        let quitMenuItem = NSMenuItem(title: "Quit", action: #selector(NSApp.terminate(_:)), keyEquivalent: "q")
        quitMenuItem.allowsKeyEquivalentWhenHidden = true
        appMenu.addItem(quitMenuItem)
        return mainMenu
    }
}
