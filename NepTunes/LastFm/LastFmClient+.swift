//
//  LastFmClient+.swift
//  NepTunes
//
//  Created by Adam Różyński on 01/06/2021.
//

import Foundation
import LastFmKit
import Combine

extension LastFmClient {
    static var live: Self {
        LastFmClient(secret: Secrets.lastFmApiSecret, apiKey: Secrets.lastFmApiKey)
    }
    
    static func mock(with dataTaskPublisher: @escaping (URLRequest) -> AnyPublisher<Data, URLError>) -> Self {
        var client = Self(secret: "secret", apiKey: "api_key")
        client.dataTaskPublisher = dataTaskPublisher
        return client
    }
}
