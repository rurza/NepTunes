//
//  ReversedOrderLabelStyle.swift
//  
//
//  Created by Adam Różyński on 22/07/2021.
//

import SwiftUI

public struct ReversedOrderLabelStyle: LabelStyle {
    
    public init() { }
    
    @ViewBuilder
    public func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.title
            configuration.icon
        }
    }
}
