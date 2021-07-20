//
//  NavigationControls.swift
//  NepTunes
//
//  Created by rurza on 19/07/2021.
//

import SwiftUI
import Shared

struct NavigationControls: View {

    @Binding var index: PageIndex
    let numberOfPages: Int

    var body: some View {
        ZStack {
            HStack {
                if index > 0 {
                    Button("Previous") {
                        withAnimation {
                            index -= 1
                        }
                    }
                }
                Spacer()
                if index != numberOfPages - 1 {
                    Button("Next") {
                        withAnimation {
                            index += 1
                        }
                    }
                }
            }
            .niceButton()
            .padding()

            PageControl(count: numberOfPages, index: $index)
        }
        .animation(nil)
    }
}

struct PageViewControls_Previews: PreviewProvider {
    static var previews: some View {
        NavigationControls(index: .constant(0), numberOfPages: 3)
    }
}
