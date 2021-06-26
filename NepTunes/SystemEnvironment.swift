//
//  SystemEnvironment.swift
//  NepTunes
//
//  Created by Adam Różyński on 05/06/2021.
//

import Foundation
import Combine
import ComposableArchitecture

@dynamicMemberLookup
struct SystemEnvironment<Environment> {
    var environment: Environment
    var mainQueue: AnySchedulerOf<DispatchQueue>
    var date: () -> Date
    var settings: SettingsProvider
    
    subscript<Dependency>(
        dynamicMember keyPath: WritableKeyPath<Environment, Dependency>
    ) -> Dependency {
        get { self.environment[keyPath: keyPath] }
        set { self.environment[keyPath: keyPath] = newValue }
    }
    
    /// Creates a live system environment with the wrapped environment provided.
    ///
    /// - Parameter environment: An environment to be wrapped in the system environment.
    /// - Returns: A new system environment.
    static func live(environment: Environment) -> Self {
        Self(
            environment: environment,
            mainQueue: .main,
            date: Date.init,
            settings: Settings()
        )
    }
    
    /// Transforms the underlying wrapped environment.
    func map<NewEnvironment>(_ transform: @escaping (Environment) -> NewEnvironment) -> SystemEnvironment<NewEnvironment> {
        .init(
            environment: transform(self.environment),
            mainQueue: self.mainQueue,
            date: self.date,
            settings: self.settings
        )
    }
}
