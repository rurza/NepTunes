//
//  AVPlayerViewRepresented.swift
//  NepTunes
//
//  Created by Adam Różyński on 17/07/2021.
//

import Cocoa
import SwiftUI
import AVKit

struct AVPlayerViewRepresented : NSViewRepresentable {
    var player : AVPlayer
    
    func makeNSView(context: Context) -> AVPlayerView {
        let view = AVPlayerView(frame: .zero)
        view.autoresizingMask = [.height, .width]
        view.controlsStyle = .none
        view.player = player
        view.videoGravity = .resizeAspectFill
        return view
    }
    
    func updateNSView(_ nsView: AVPlayerView, context: Context) {

    }
}
