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
public struct SystemEnvironment<Environment> {
    public var localEnvironment: Environment
    public var mainQueue: AnySchedulerOf<DispatchQueue>
    public var runLoop: AnySchedulerOf<RunLoop>
    public var date: () -> Date
    public var settings: SettingsProvider
    
    public subscript<Dependency>(
        dynamicMember keyPath: WritableKeyPath<Environment, Dependency>
    ) -> Dependency {
        get { self.localEnvironment[keyPath: keyPath] }
        set { self.localEnvironment[keyPath: keyPath] = newValue }
    }
    
    /// Creates a live system environment with the wrapped environment provided.
    ///
    /// - Parameter environment: An environment to be wrapped in the system environment.
    /// - Returns: A new system environment.
    public static func live(environment: Environment) -> Self {
        Self(
            localEnvironment: environment,
            mainQueue: .main,
            runLoop: .main,
            date: Date.init,
            settings: Settings()
        )
    }
    
    /// Transforms the underlying wrapped environment.
    public func map<NewEnvironment>(_ transform: @escaping (Environment) -> NewEnvironment) -> SystemEnvironment<NewEnvironment> {
        .init(
            localEnvironment: transform(self.localEnvironment),
            mainQueue: self.mainQueue,
            runLoop: self.runLoop,
            date: self.date,
            settings: self.settings
        )
    }
}
