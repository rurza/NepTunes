//
//  AppDelegate.swift
//  NepTunes
//
//  Created by Adam Różyński on 28/04/2021.
//

import Cocoa
import SwiftUI
import ComposableArchitecture
import Plugins

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    var window: NSWindow!
    
    var playerObserver: PlayerObserver?
    var store: Store<AppState, AppAction>!
    var pluginInstance: PluginsInterface?
    var note: NSObjectProtocol?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        store = Store(initialState: AppState(), reducer: appReducer, environment: AppEnvironment())
        playerObserver = PlayerObserver(store: store)
        // Create the SwiftUI view that provides the window contents.
        let bundle = Bundle.main
        let pluginsPath = bundle.builtInPlugInsPath!
        let statusBarPlugin = Bundle(path: pluginsPath + "/StatusBarInfo.nepext")
        let principalClass = statusBarPlugin?.principalClass as? PluginsInterface.Type
        pluginInstance = initPlugin(from: principalClass)
       
        Bundle.main.loadAppleScriptObjectiveCScripts()
        let musicAppleScriptClass: AnyClass = NSClassFromString("MusicScript")!
        let bridge = musicAppleScriptClass.alloc() as! MusicBridge


        note = DistributedNotificationCenter.default().addObserver(forName: NSNotification.Name(rawValue: "com.apple.Music.playerInfo"), object: nil, queue: nil) { note in
        //    print(note.userInfo as Any?)
            print(bridge.currentTrack)
            if let track = bridge.currentTrack {
                self.pluginInstance?.trackDidChange(track.title, byArtist: track.artist)
            }
        }

        
        let contentView = ContentView()
        // Create the window and set the content view.
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 300),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.center()
        window.setFrameAutosaveName("Main Window")
        window.contentView = NSHostingView(rootView: contentView)
        window.makeKeyAndOrderFront(nil)
    }

    func initPlugin(from type: PluginsInterface.Type?) -> PluginsInterface? {
        if let cls = type {
            let plugin = cls.init()
            return plugin
        }
        return nil
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }


}

