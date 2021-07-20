//
//  main.swift
//  NepTunes
//
//  Created by Adam Różyński on 19/07/2021.
//

import Cocoa

private let app = NSApplication.shared
private let appDelegate = AppDelegate()

app.delegate = appDelegate
_ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
