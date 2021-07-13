//
//  LastFmState.swift
//  NepTunes
//
//  Created by Adam Różyński on 13/05/2021.
//

import Foundation

struct LastFmState: Equatable {
    var loginState: LastFmLoginState?
}

struct LastFmLoginState: Equatable {
    var username: String?
    var password: String?
}
