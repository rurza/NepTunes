//
//  PlayerObserver.swift
//  NepTunes
//
//  Created by Adam Różyński on 16/05/2021.
//

import Foundation
import Cocoa

class PlayerObserver {
    
    init() {
//        NSWorkspace.shared.runningApplications
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(appDidLaunch(_:)), name: NSWorkspace.didLaunchApplicationNotification, object: nil)
    }
    
    @objc func appDidLaunch(_ note: Notification) {
        let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
        print(app)
    }
    
}
