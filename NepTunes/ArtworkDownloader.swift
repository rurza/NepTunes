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
    var getArtworkForAlbumAndArtist: (String, String) -> Effect<Data, Error>
    var getArtwork: (URL) -> Effect<Data, Error>
    
    struct NotFound: Error { }
    
    static let live
        = Self(
            getArtworkForAlbumAndArtist: { album, artist in
                DeezerClient().searchForAlbum(named: album, byArtist: artist)
                    .tryCompactMap { response -> URL? in
                        if let cover = response.data.first?.album?.bigCover {
                            return cover
                        }
                        throw NotFound()
                    }
                    .flatMap {
                        URLSession.shared
                            .dataTaskPublisher(for: $0)
                            .mapError { $0 as Error }
                    }
                    .map(\.data)
                    .eraseToEffect()
            },
            getArtwork: { url in
                URLSession.shared
                    .dataTaskPublisher(for: url)
                    .mapError { $0 as Error }
                    .map(\.data)
                    .eraseToEffect()
            }
        )
    
    static func mock(data: @escaping () -> Data) -> Self {
        Self(getArtworkForAlbumAndArtist: { _, _ in Effect(value: Data()) }, getArtwork: { _ in Effect(value: Data()) })
    }
}

