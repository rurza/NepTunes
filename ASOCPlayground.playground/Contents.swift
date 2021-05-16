import AppleScriptObjC
import PlaygroundSupport

// AppleScriptObjC setup
Bundle.main.loadAppleScriptObjectiveCScripts()
// create an instance of iTunesBridge script object for Swift code to use
let musicAppleScriptClass: AnyClass = NSClassFromString("MusicScript")!
let bridge = musicAppleScriptClass.alloc() as! MusicBridge


let note = DistributedNotificationCenter.default().addObserver(forName: NSNotification.Name(rawValue: "com.apple.Music.playerInfo"), object: nil, queue: nil) { note in
//    print(note.userInfo as Any?)
    print(bridge.currentTrack)
}

PlaygroundPage.current.needsIndefiniteExecution = true
