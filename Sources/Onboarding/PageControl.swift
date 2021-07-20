//
//  PageControl.swift
//  NepTunes
//
//  Created by Adam Różyński on 18/07/2021.
//

import SwiftUI

struct PageControl: View {
    
    let count: Int
    @Binding var index: PageIndex
    private let size: CGFloat = 8
    
    var body: some View {
        ZStack {
            HStack(spacing: size) {
                ForEach(0..<count) { i in
                    Rectangle()
                        .foregroundColor(Color(NSColor.tertiaryLabelColor))
                        .onTapGesture {
                            withAnimation {
                                index = PageIndex(currentIndex: i, oldIndex: index.currentIndex)
                            }
                        }
                }
            }
            Circle()
                .foregroundColor(Color(NSColor.secondaryLabelColor))
                .frame(width: size, height: size)
                .position(x: size/2 + CGFloat(index.currentIndex) * 2 * size, y: size/2)
                .animation(.spring(), value: index.currentIndex)
        }
        .mask(
            HStack(spacing: size) {
                ForEach(0..<count) { index in
                    Circle()
                        .frame(width: size, height: size)
                }
            }
        )
        .frame(width: width, height: size)
        .animation(nil)
        
    }
    
    var width: CGFloat {
        (size * CGFloat(count)) + (size * (CGFloat(count) - 1))
    }
    
}

struct PageControl_Previews: PreviewProvider {
    static var previews: some View {
        PageControl(count: 4, index: .constant(2))
    }
}
