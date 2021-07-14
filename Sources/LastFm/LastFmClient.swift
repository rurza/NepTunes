//
//  LastFmClient.swift
//  
//
//  Created by Adam Różyński on 14/07/2021.
//

import Foundation
import ComposableArchitecture
import LastFmKit

public struct LastFmClient {
    public var logInUser: (String, String) -> Effect<LastFmSession, Error>
    public var getAvatar: (String) -> Effect<Data, Error>
}

public extension LastFmClient {
    static let live: Self = {
        let client = LastFmKit.LastFmClient(secret: Secrets.lastFmApiSecret, apiKey: Secrets.lastFmApiKey)
        return Self(
            logInUser: { username, password in
                client.logInUser(username, password: password).eraseToEffect()
            },
            getAvatar: { username in
                client.getUserInfo(username)
                    .compactMap { $0.images?.first?.url }
                    .flatMap { avatarURL in
                        URLSession.shared
                            .dataTaskPublisher(for: avatarURL)
                            .mapError { $0 as Error }
                            .eraseToAnyPublisher()
                    }
                    .map(\.data)
                    .eraseToEffect()
            })
    }()
}
