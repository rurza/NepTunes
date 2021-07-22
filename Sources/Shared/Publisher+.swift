//
//  Publisher+.swift
//  NepTunes
//
//  Created by Adam Różyński on 05/06/2021.
//

import Combine

public extension Publisher {
    func retry<T: Scheduler>(
        _ retries: Int,
        delay: T.SchedulerTimeType.Stride,
        scheduler: T
    ) -> AnyPublisher<Output, Failure> {
        self.catch { _ in
            Just(())
                .delay(for: delay, scheduler: scheduler)
                .flatMap { _ in self }
                .retry(retries > 0 ? retries - 1 : 0)
        }
        .eraseToAnyPublisher()
    }
    
    func retry<T: Scheduler>(
        _ retries: Int,
        delay: T.SchedulerTimeType.Stride,
        scheduler: T,
        condition: @escaping (Failure) -> Bool
    ) -> AnyPublisher<Output, Failure> {
        return self.catch { (error: Failure) -> AnyPublisher<Output, Failure> in
            if condition(error) {
                return Just(())
                    .delay(for: delay, scheduler: scheduler)
                    .flatMap { _ in self }
                    .retry(retries > 0 ? retries - 1 : 0)
                    .eraseToAnyPublisher()
            } else {
                return Fail(error: error).eraseToAnyPublisher()
            }
        }
        .eraseToAnyPublisher()
        
    }
}
