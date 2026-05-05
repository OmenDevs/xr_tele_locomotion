//
//  InteractionConfig.swift
//  Locomotion
//
//  Created by Julio Enrique Sanchez Guajardo on 09/04/26.
//

import Foundation

@Observable
class InteractionConfig {
    var selectedInteraction: InteractionProtocol = .joystick2D
}

enum InteractionProtocol: String, CaseIterable, Identifiable {
    case joystick2D = "Joystick 2D"
    case joystick3D = "Joystick 3D"
    case gestureBased = "Gesture Based"

    var id: Self { self }
}
