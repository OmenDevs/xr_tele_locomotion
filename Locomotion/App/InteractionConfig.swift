import Foundation

@Observable
class InteractionConfig {
    var selectedInteraction: InteractionProtocol = .joystick3D
}

enum InteractionProtocol: String, CaseIterable, Identifiable {
    case joystick3D = "Joystick 3D"
    case gestureBased = "Astrolabium"
    case joystick2D = "Joystick 2D"

    var id: Self { self }
}
