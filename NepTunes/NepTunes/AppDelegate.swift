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
import Onboarding

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    private var onboardingWindow: NSWindow?
    private let viewStore = ViewStore(store)
    private var cancellables = Set<AnyCancellable>()
    private lazy var statusBarMenuController = StatusBarMenuController(viewStore: viewStore)
    private lazy var statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        addMenuToStatusBar()
        setUpBindings()
        viewStore.send(.appLifecycleAction(.appDidLaunch))
        
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func setUpBindings() {

        let onboardingStore: Store<OnboardingState?, OnboardingAction>
            = store.scope(state: \.onboardingState, action: AppAction.onboardingAction)
        onboardingStore
            .ifLet { [weak self] store in
                self?.showOnboarding(store: store)
        }
        .store(in: &cancellables)
    }
    
    func showOnboarding(store: Store<OnboardingState, OnboardingAction>) {
        
        let onboardingView = OnboardingContentView(store: store).frame(minWidth: 460, maxWidth: 460, minHeight: 480).fixedSize(horizontal: false, vertical: true)//

        // Create the window and set the content view.
        let window  = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1, height: 1000),
            styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView],
            backing: .buffered, defer: false)
        
        window.isReleasedWhenClosed = true
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.contentView = NSHostingView(rootView: onboardingView)
        window.center()
        window.title = "NepTunes Quick Start Guide"
        
        window.makeKeyAndOrderFront(nil)
        self.onboardingWindow = window
    }
    
    func addMenuToStatusBar() {
        let menu = statusBarMenuController.menu()
        statusItem.menu = menu
        statusItem.button?.image = NSImage(named: "status bar icon")
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

