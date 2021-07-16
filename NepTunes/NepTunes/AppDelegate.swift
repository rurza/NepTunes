//
//  AppDelegate.swift
//  NepTunes
//
//  Created by Adam Różyński on 28/04/2021.
//

import Cocoa
import SwiftUI
import ComposableArchitecture
import AppCore
import Combine

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    var onboardingWindow: NSWindow?
    let viewStore = ViewStore(store)
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ aNotification: Notification) {

//        note = DistributedNotificationCenter.default().addObserver(forName: NSNotification.Name(rawValue: "com.apple.Music.playerInfo"), object: nil, queue: nil) { note in
//        //    print(note.userInfo as Any?)
//            print(bridge.currentTrack)
//            if let track = bridge.currentTrack {
//                self.pluginInstance?.trackDidChange(track.title, byArtist: track.artist)
//            }
//        }
        setUpBindings()
        viewStore.send(.appLifecycleAction(.appDidLaunch))
    }
    
    func setUpBindings() {
        viewStore.publisher
            .shouldShowOnboarding
            .sink { [weak self] shouldShowOnboarding in
                guard shouldShowOnboarding else { return }
                self?.showOnboarding()
            }
            .store(in: &cancellables)
    }
    
    func showOnboarding() {
        
        let welcomeView = WelcomeView()
        // Create the window and set the content view.
        let window  = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 400),
            styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView],
            backing: .buffered, defer: false)
        
        window.isReleasedWhenClosed = true
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.setFrameAutosaveName("NepTunes Quick Start Guide")
        window.contentView = NSHostingView(rootView: welcomeView)
        window.makeKeyAndOrderFront(nil)
        window.center()
        window.title = "NepTunes Quick Start Guide"
        self.onboardingWindow = window
    }
    


    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    // Plugins
    
    //        let bundle = Bundle.main
    //        let pluginsPath = bundle.builtInPlugInsPath!
    //        let statusBarPlugin = Bundle(path: pluginsPath + "/StatusBarInfo.nepext")
    //        let principalClass = statusBarPlugin?.principalClass as? PluginsInterface.Type
    //        pluginInstance = initPlugin(from: principalClass)
    //
    //        Bundle.main.loadAppleScriptObjectiveCScripts()
    //        let musicAppleScriptClass: AnyClass = NSClassFromString("MusicScript")!
    //        let bridge = musicAppleScriptClass.alloc() as! MusicBridge
    
    func application(_ sender: NSApplication, openFile filename: String) -> Bool {
        let fs = FileManager.default
        if let path = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true).first {
            let name = (filename as NSString).lastPathComponent
            let folderPath = path + "/NepTunes/PlugIns"
            do {
                try fs.createDirectory(atPath: folderPath, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print(error)
            }
            let finalPath = folderPath + "/\(name)"
            do {
                try fs.moveItem(atPath: filename, toPath: finalPath)
            } catch {
                print(error)
            }
        }
        return false
    }


}

