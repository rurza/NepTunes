//
//  ArtworkDownloader.swift
//  NepTunes
//
//  Created by Adam Różyński on 08/06/2021.
//

import Foundation
import ComposableArchitecture
import DeezerClient

struct ArtworkDownloader {
    var getArtworkURL: (String) -> Effect<Data, Error>
    
    static let live = Self(getArtworkURL: { album in
        DeezerClient().searchForAlbum(named: album).compactMap { $0.data.first?.bigCover }.flatMap { URLSession.shared.dataTaskPublisher(for: $0).mapError { $0 as Error } }.map(\.data).eraseToEffect()
    })
}

