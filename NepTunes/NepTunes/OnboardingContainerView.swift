//
//  OnboardingContainerView.swift
//  NepTunes
//
//  Created by Adam Różyński on 17/07/2021.
//

import SwiftUI

struct OnboardingContainerView: View {
    
    @State private var currentPage = 0
    @State private var oldPage = 0
    
    var body: some View {
        VStack(spacing: 0) {
            Group {
                if currentPage == 0 {
                    WelcomeView()
                } else if currentPage == 1 {
                    PermissionsView()
                }
            }
            .transition(.stackTransition(oldIndex: oldPage, newIndex: currentPage))
            .ignoresSafeArea(.all, edges: .top)
            Spacer(minLength: 0)
            OnboardingNavigationControls(currentPage: $currentPage, oldPage: $oldPage, numberOfPages: 4)
        }
        .animation(.spring(), value: currentPage)

    }

}

struct OnboardingContainerView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingContainerView()
            .frame(width: 460)
            .previewLayout(.sizeThatFits)
    }
}

extension AnyTransition {
    static func stackTransition(oldIndex: Int, newIndex: Int) -> AnyTransition {
        if newIndex > oldIndex {
            let appear = AnyTransition.move(edge: .trailing)
            let disappear = AnyTransition.move(edge: .leading)
            return .asymmetric(insertion: appear, removal: disappear)
        } else {
            let appear = AnyTransition.move(edge: .leading)
            let disappear = AnyTransition.move(edge: .trailing)
            return .asymmetric(insertion: appear, removal: disappear)
        }
    }

    static func reversedStackTransition(oldIndex: Int, newIndex: Int) -> AnyTransition {
        if newIndex >= oldIndex {
            let appear = AnyTransition.move(edge: .leading)
            let disappear = AnyTransition.move(edge: .trailing)
            return .asymmetric(insertion: appear, removal: disappear)
        } else {
            let appear = AnyTransition.move(edge: .trailing)
            let disappear = AnyTransition.move(edge: .leading)
            return .asymmetric(insertion: appear, removal: disappear)
        }
    }
}

