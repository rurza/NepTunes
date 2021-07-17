//
//  PageView.swift
//  NepTunes
//
//  Created by Adam Różyński on 17/07/2021.
//

import SwiftUI

struct PageView<Content: View>: View {
    
    private let content: () -> Content
    @Binding private var currentIndex: Int
    
    init(currentIndex: Binding<Int>,
         @ViewBuilder content: @escaping () -> Content) {
        self._currentIndex = currentIndex
        self.content = content
    }
    
    var body: some View {
        GeometryReader { geometryProxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    content()
                        .frame(maxWidth: geometryProxy.size.width)
                    
                }
            }
        }
    }
    
}
