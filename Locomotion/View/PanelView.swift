//
//  PanelView.swift
//  Locomotion
//
//  Created by Can Dindar on 05/03/26.
//

import SwiftUI

struct PanelView: View {
    var body: some View {
        VStack(spacing: 10) {
            ControlsView()

            CameraSwitchView()
        }
        .padding()
    }
}

#Preview {
    PanelView()
}
