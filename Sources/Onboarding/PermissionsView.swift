//
//  PermissionsView.swift
//  NepTunes
//
//  Created by Adam Różyński on 17/07/2021.
//

import SwiftUI
import Shared

struct PermissionsView: View {
    
    @StateObject private var model = PlayerViewModel(name: "tutorial")
    
    var body: some View {
        VStack(spacing: 20) {
            AVPlayerViewRepresented(player: model.player)
                .frame(height: 240)
            Text("Access to the apps")
                .font(.title)
        }
        .onAppear {
            model.play()
        }
    }
}

struct PermissionsView_Previews: PreviewProvider {
    static var previews: some View {
        PermissionsView()
    }
}
