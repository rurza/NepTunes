//
//  OnboardingContainerView.swift
//  NepTunes
//
//  Created by Adam Różyński on 17/07/2021.
//

import SwiftUI

struct OnboardingContainerView: View {
    
    @State private var currentPage = 0
    
    var body: some View {
        VStack {
            Group {
                if currentPage == 0 {
                    WelcomeView()
                } else if currentPage == 1 {
                    PermissionsView()
                }
            }
            .ignoresSafeArea(.all, edges: .top)

            ZStack {
                HStack {
                    if currentPage > 0 {
                        Button("Previous") { currentPage -= 1 }
                    }
                    Spacer()
                    Button("Next") { currentPage += 1 }
                }
                .padding()
                PageControl(count: 2, currentIndex: $currentPage)
            }
        }
    }
}

struct OnboardingContainerView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingContainerView()
            .frame(width: 460)
    
    }
}
