//
//  UserReducerTests.swift
//  
//
//  Created by rurza on 14/07/2021.
//

import XCTest
import ComposableArchitecture
import Combine
@testable import LastFmKit
@testable import Shared
@testable import LastFm

final class UserReducerTests: XCTestCase {
    
    func testReducer() throws {
        
        let uuid = UUID().uuidString
        
        let avatarData = Data()
        
        let session: (String) -> LastFmSession = { username in
            LastFmSession(name: username,
                          key: uuid,
                          subscriber: 1)
        }
        
        let lastFmClientMock = LastFm.LastFmClient { username, _ in
            return Effect(value: session(username))
        } getAvatar: { _ in
            return Effect(value: avatarData)
        }
        
        
        let lastFmEnvironment = LastFmEnvironment(lastFmClient: lastFmClientMock)
        
        let settings = MockSettings()
        
        let environment = SystemEnvironment(localEnvironment: lastFmEnvironment,
                                            mainQueue: DispatchQueue.test.eraseToAnyScheduler(),
                                            runLoop: RunLoop.test.eraseToAnyScheduler(),
                                            date: { Date() },
                                            settings: settings)
        
        let testStore = TestStore(initialState: LastFmState(),
                                  reducer: lastFmUserReducer,
                                  environment: environment)
        
        //
        // Typing username and password
        //
        let username = "rurza"
        testStore.send(.setUsername(username)) { state in
            state.loginState = LastFmLoginState(username: username, password: nil)
        }
        
        let password = "Password"
        testStore.send(.setPassword(password)) { state in
            state.loginState = LastFmLoginState(username: username, password: password)
        }
        
        testStore.send(.logOut) { state in
            state.loginState = nil
        }
        
        // now we'll change the order of first providing password and then the username
        testStore.send(.setPassword(password)) { state in
            state.loginState = LastFmLoginState(username: nil, password: password)
        }
        
        testStore.send(.setUsername(username)) { state in
            state.loginState = LastFmLoginState(username: username, password: password)
        }
        
        
        testStore.send(.logOut) { state in
            state.loginState = nil
        }
        
        //
        // user login
        //
        XCTAssertNil(settings.session)
        testStore.send(.setUsername(username)) { state in
            state.loginState = LastFmLoginState(username: username, password: nil)
        }
        testStore.send(.setPassword(password)) { state in
            state.loginState = LastFmLoginState(username: username, password: password)
        }
        testStore.send(.logIn)
        
        testStore.receive(.userLoginResponse(.success(session(username)))) { state in
            state.loginState = nil
        }
        XCTAssertEqual(settings.session, session(username).key)
        XCTAssertEqual(settings.username, session(username).name)

        
        //
        // Get avatar
        //
        testStore.send(.getUserAvatar)
        testStore.receive(.userAvatarResponse(.success(avatarData))) { state in
            state.userAvatarData = avatarData
        }
        
        //
        // Log out
        //
        testStore.send(.logOut) { state in
            state.loginState = nil
            state.userAvatarData = nil
        }
        
    }
    
}
