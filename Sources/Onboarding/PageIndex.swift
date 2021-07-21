//
//  PageIndex.swift
//  
//
//  Created by Adam Różyński on 20/07/2021.
//

import Foundation

public struct PageIndex: ExpressibleByIntegerLiteral, Equatable {
    
    private(set) var currentIndex: Int
    private(set) var oldIndex: Int
    
    internal init(currentIndex: Int, oldIndex: Int) {
        self.currentIndex = currentIndex
        self.oldIndex = oldIndex
    }
    
    public init(integerLiteral value: IntegerLiteralType) {
        currentIndex = value
        oldIndex = value
    }
    
    internal static func +=(lhs: inout PageIndex, rhs: Int) {
        lhs.oldIndex = lhs.currentIndex
        lhs.currentIndex = lhs.currentIndex + rhs
    }
    
    internal static func -=(lhs: inout PageIndex, rhs: Int) {
        lhs.oldIndex = lhs.currentIndex
        lhs.currentIndex = lhs.currentIndex - rhs
    }
    
    public static func ==(lhs: PageIndex, rhs: PageIndex) -> Bool {
        lhs.currentIndex == rhs.currentIndex
    }
    
    internal static func ==(lhs: PageIndex, rhs: Int) -> Bool {
        lhs.currentIndex == rhs
    }
    
    internal static func !=(lhs: PageIndex, rhs: Int) -> Bool {
        lhs.currentIndex != rhs
    }
    
    internal static func >(lhs: PageIndex, rhs: Int) -> Bool {
        lhs.currentIndex > rhs
    }
    
    internal static func <(lhs: PageIndex, rhs: Int) -> Bool {
        lhs.currentIndex < rhs
    }
}
