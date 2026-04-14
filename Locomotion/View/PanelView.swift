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
            CameraSwitchView()
        }
        .padding()
    }
}

#Preview {
    PanelView()
}
