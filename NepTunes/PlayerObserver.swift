//
//  PlayerObserver.swift
//  NepTunes
//
//  Created by Adam Różyński on 16/05/2021.
//

import Foundation
import Cocoa
import ComposableArchitecture
import SwiftCurry

class PlayerObserver {
    
    let viewStore: ViewStore<AppState, AppAction>
    
    init(store: Store<AppState, AppAction>) {
        viewStore = ViewStore(store, removeDuplicates: { lhs, rhs in
            return lhs.currentPlayer == rhs.currentPlayer
        })
        verifyCurrentlyRunningApps()
        NSWorkspace.shared
            .notificationCenter
            .addObserver(self,
                         selector: #selector(appDidLaunch(_:)),
                         name: NSWorkspace.didLaunchApplicationNotification,
                         object: nil)
    }
    
    func verifyCurrentlyRunningApps() {
        // we want to sort apps, so in case of two running at the same time, we won't choose one on some arbitrary criteria
        // fix: implicit unwrap
//        let comparison = their(^(\NSRunningApplication.bundleIdentifier!), >)
        let runningApps = NSWorkspace.shared.runningApplications.sorted { app1, app2 in
            app1.bundleIdentifier ?? "" > app2.bundleIdentifier ?? ""
        }
        for runningApp in runningApps {
            if let player = playerTypeForRunningApp(runningApp) {
                viewStore.send(.newPlayerIsAvailable(player))
                break
            }
        }
    }
    
    @objc func appDidLaunch(_ note: Notification) {
        let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
        if let playerApp = playerTypeForRunningApp(app) {
            viewStore.send(.newPlayerIsAvailable(playerApp))
        }
    }
    
    func playerTypeForRunningApp(_ runningApplication: NSRunningApplication?) -> PlayerType? {
        guard let bundleIdentifier = runningApplication?.bundleIdentifier else { return nil }
        return PlayerType(rawValue: bundleIdentifier)
    }
    
    
}
