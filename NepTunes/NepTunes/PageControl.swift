//
//  PageControl.swift
//  NepTunes
//
//  Created by Adam Różyński on 18/07/2021.
//

import SwiftUI

struct PageControl: View {
    
    let count: Int
    @Binding var currentIndex: Int
    
    var body: some View {
        HStack {
            ForEach(0..<count) { index in
                Circle()
                    .frame(width: 10, height: 10)
                    .foregroundColor(index == currentIndex ? .primary : .secondary)
                    .onTapGesture {
                        currentIndex = index
                    }
            }
        }
    }
}

struct PageControl_Previews: PreviewProvider {
    static var previews: some View {
        PageControl(count: 4, currentIndex: .constant(2))
    }
}
