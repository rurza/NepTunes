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
            HStack {
                if currentPage > 0 {
                    Button("Previous") {
                        withAnimation {
                            currentPage -= 1
                        }
                    }
                }
                Spacer()
                Button("Next") {
                    withAnimation {
                        currentPage += 1
                    }
                }
            }
            .padding()
            .animation(nil)
        }
        .ignoresSafeArea(.all, edges: .top)
        .frame(width: 460)

    }
}

struct OnboardingContainerView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingContainerView()
            .frame(width: 460)
    }
}
