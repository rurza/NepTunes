//
//  AppEnvironment.swift
//  NepTunes
//
//  Created by Adam Różyński on 13/05/2021.
//

import Foundation
import LastFmKit
import Combine
import ComposableArchitecture

struct AppEnvironment {

    var mainQueue: AnySchedulerOf<DispatchQueue> = DispatchQueue.main.eraseToAnyScheduler()
    var lastFmClient: LastFmClient = .live
    
}

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

