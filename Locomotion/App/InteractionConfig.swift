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
    /// The server IP address entered by the user (e.g., "https://192.168.1.10:8000/offer")
    var serverAddress: String = ""
}

enum InteractionProtocol: String, CaseIterable, Identifiable {
    case joystick2D = "Joystick 2D"
    case joystick3D = "Joystick 3D"
    case gestureBased = "Gesture Based"

    var id: Self { self }
}
