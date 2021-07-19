//
//  OnboardingNavigationControls.swift
//  NepTunes
//
//  Created by rurza on 19/07/2021.
//

import SwiftUI

struct OnboardingNavigationControls: View {

    @Binding var currentPage: Int
    @Binding var oldPage: Int
    let numberOfPages: Int

    var body: some View {
        ZStack {
            HStack {
                if currentPage > 0 {
                    Button("Previous") {
                        withAnimation {
                            oldPage = currentPage
                            currentPage -= 1
                        }
                    }
                }
                Spacer()
                if currentPage != numberOfPages - 1 {
                    Button("Next") {
                        withAnimation {
                            oldPage = currentPage
                            currentPage += 1
                        }
                    }
                }
            }
            .niceButton()
            .padding()

            PageControl(count: numberOfPages, currentIndex: $currentPage, oldIndex: $oldPage)
        }
        .animation(nil)
    }
}

struct PageViewControls_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingNavigationControls(currentPage: .constant(0), oldPage: .constant(1), numberOfPages: 3)
    }
}
