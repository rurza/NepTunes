//
//  LastFmClient.swift
//  
//
//  Created by Adam Różyński on 14/07/2021.
//

import Foundation
import ComposableArchitecture
import LastFmKit
import Combine

public struct LastFmUserClient {
    var logInUser: (String, String) -> Effect<LastFmSession, Error>
    var getAvatar: (String) -> Effect<Data, Error>
}

public extension LastFmUserClient {
    static let live: Self = {
        let client = LastFmKit.LastFmClient(secret: Secrets.lastFmApiSecret, apiKey: Secrets.lastFmApiKey)
        return Self(
            logInUser: { username, password in
                client.logInUser(username, password: password).eraseToEffect()
            },
            getAvatar: { username in
                client.getUserInfo(username)
                    .compactMap { $0.images?.last?.url }
                    .map { URLRequest(url: $0, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 30) }
                    .flatMap { request -> AnyPublisher<(data: Data, response: URLResponse), Error> in
                        URLSession.shared
                            .dataTaskPublisher(for: request)
                            .mapError { $0 as Error }
                            .eraseToAnyPublisher()
                    }
                    .map(\.data)
                    .eraseToEffect()
            })
    }()
}
