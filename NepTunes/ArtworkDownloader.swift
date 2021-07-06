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
    var getArtworkURL: (String, String) -> Effect<Data, Error>
    
    struct NotFound: Error { }
    
    static let live = Self(getArtworkURL: { album, artist in
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
    })
    
    static func mock(data: @escaping () -> Data) -> Self {
        Self { _, _  in
            Effect(value: data())
        }
    }
}
