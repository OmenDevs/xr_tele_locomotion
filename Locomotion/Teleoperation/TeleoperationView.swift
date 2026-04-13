//
//  TeleoperationView.swift
//  Locomotion
//
//  Created by Julio Enrique Sanchez Guajardo on 10/04/26.
//

import SwiftUI
import RealityKit

struct TeleoperationView: View {
    @State private var frameSubscription: EventSubscription?
    @Environment(InteractionConfig.self) private var interactionConfig
    var body: some View {
        RealityView { content in
            frameSubscription = content.subscribe(to: SceneEvents.Update.self) { event in
                let deltaTime = event.deltaTime
                print(deltaTime)
            }
        }
    }
}

#Preview {
    TeleoperationView()
}
