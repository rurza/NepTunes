//
//  NSWindow+Center.swift
//  NepTunes
//
//  Created by Adam Różyński on 17/07/2021.
//

import Cocoa

extension NSWindow {
    public func positionCenter() {
        if let screenSize = screen?.visibleFrame.size {
            self.setFrameOrigin(NSPoint(x: (screenSize.width-frame.size.width)/2, y: (screenSize.height-frame.size.height)/2))
        }
    }
}
