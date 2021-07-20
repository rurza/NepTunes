//
//  SystemEnvironment+Mock.swift
//  
//
//  Created by Adam Różyński on 20/07/2021.
//

import Shared
import LastFm
import Foundation

extension SystemEnvironment {
    
    class Settings: SettingsProvider {
        var session: String? = nil
        
        var username: String? = nil
        
        var scrobblePercentage: UInt = 50
        
        var showCover: Bool = false
        
        var onboardingIsDone: Bool = false
        
    }
    
    static func mock(environment: Environment) -> Self {
        Self(
            localEnvironment: environment,
            mainQueue: DispatchQueue.immediate.eraseToAnyScheduler(),
            runLoop: RunLoop.immediate.eraseToAnyScheduler(),
            date: Date.init,
            settings: Settings()
        )
    }
}
