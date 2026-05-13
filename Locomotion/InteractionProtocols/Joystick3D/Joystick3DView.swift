import SwiftUI
import RealityKit
import RealityKitContent

struct Joystick3DView: View {
    @State private var frameSubscription: EventSubscription?
    @State private var manipulationSubscription: EventSubscription?
    @State private var handSkeletonProvider = HandSkeletonProvider()
    // Reads the headset's world position so the deck can face the user.
    @State private var devicePoseProvider = DevicePoseProvider()
    // Retained so the manipulation subscription can reference the deck entity.
    @State private var deckEntity: Entity?
    // The USDZ's baked-in root rotation — composed with our Y-only yaw so the
    // model stays upright instead of being overwritten flat.
    @State private var deckBaseOrientation: simd_quatf = simd_quatf()
    @Environment(HandSkeletonData.self) private var skeletonData

    var body: some View {
        RealityView { content in
            handSkeletonProvider.skeletonData = skeletonData
            PinchInputViewModel.shared.skeletonData = skeletonData
            Task { await handSkeletonProvider.start() }
            Task { await devicePoseProvider.start() }

            if let deck = try? await Entity(named: "joystick3d", in: realityKitContentBundle) {
                deck.position = SIMD3<Float>(0, 0.7, -1.0)
                content.add(deck)
                deckEntity = deck
                // Capture the USDZ's baked-in root rotation so we can compose
                // our Y-only yaw on top of it instead of replacing it.
                deckBaseOrientation = deck.orientation(relativeTo: nil)

                // Enables pinch-and-drag on the deck via a box-shaped grab zone.
                ManipulationComponent.configureEntity(
                    deck,
                    allowedInputTypes: .all,
                    collisionShapes: [.generateBox(width: 0.48, height: 0.26, depth: 0.07)])
                if var manipulation = deck.components[ManipulationComponent.self] {
                    manipulation.releaseBehavior = .stay
           manipulation.dynamics.scalingBehavior = .none
                    deck.components.set(manipulation)
                }

                // Re-orient to face the user only while dragging, not every frame.
                manipulationSubscription = content.subscribe(
                    to: ManipulationEvents.DidUpdateTransform.self, on: deck
                ) { [self] _ in
                    if let deviceTransform = devicePoseProvider.currentDeviceTransform() {
                        faceDeviceYOnly(entity: deck, deviceTransform: deviceTransform)
                    }
                }

                PinchInputViewModel.shared.deck = deck.findEntity(named: "Dock")

                if let head = deck.findEntity(named: "Joystick_Head"),
                   let base = deck.findEntity(named: "Joystick_Base") {
                    let joystickParent = Entity()
                    joystickParent.name = "JoystickParent"
                    joystickParent.setPosition(head.position(relativeTo: nil), relativeTo: nil)
                    head.setParent(joystickParent, preservingWorldTransform: true)
                    base.setParent(joystickParent, preservingWorldTransform: true)
                    joystickParent.setParent(deck, preservingWorldTransform: true)
                    PinchInputViewModel.shared.joystickHandle = joystickParent
                    PinchInputViewModel.shared.joystickRestPosition = joystickParent.position
                }

                if let head = deck.findEntity(named: "Lever_head"),
                   let base = deck.findEntity(named: "Lever_Base") {
                    let leverParent = Entity()
                    leverParent.name = "LeverParent"
                    leverParent.setPosition(head.position(relativeTo: nil), relativeTo: nil)
                    head.setParent(leverParent, preservingWorldTransform: true)
                    base.setParent(leverParent, preservingWorldTransform: true)
                    leverParent.setParent(deck, preservingWorldTransform: true)
                    PinchInputViewModel.shared.leverHandle = leverParent
                    PinchInputViewModel.shared.leverRestPosition = leverParent.position
                }
            }

            frameSubscription = content.subscribe(to: SceneEvents.Update.self) { _ in
                PinchInputViewModel.shared.update()

                let maxOffset: Float = 0.04
                if let stick = PinchInputViewModel.shared.joystickHandle,
                   let rest = PinchInputViewModel.shared.joystickRestPosition {
                    let offsetX = Float(InputViewModel.shared.velocityX) * maxOffset
                    let offsetY = Float(-InputViewModel.shared.velocityY) * maxOffset
                    stick.position = mix(stick.position, rest + SIMD3<Float>(offsetX, -offsetY, 0), t: 0.2)
                }
                if let lever = PinchInputViewModel.shared.leverHandle,
                   let rest = PinchInputViewModel.shared.leverRestPosition {
                    let offsetX = Float(InputViewModel.shared.angularVelocity) * maxOffset
                    lever.position = mix(lever.position, rest + SIMD3<Float>(offsetX, 0, 0), t: 0.2)
                }
            }
        }
    }

    /// Rotates the entity around Y only so it faces the device head.
    /// X and Z rotation are blocked — deck stays upright at all times.
    private func faceDeviceYOnly(entity: Entity, deviceTransform: simd_float4x4) {
        let devicePosition = deviceTransform.position
        let deckPosition = entity.position(relativeTo: nil)

        var directionToDevice = devicePosition - deckPosition
        directionToDevice.y = 0

        let distance = simd_length(directionToDevice)
        guard distance > 0.001 else { return }
        directionToDevice /= distance

        let yawAngle = atan2(directionToDevice.x, directionToDevice.z)
        let yawRotation = simd_quatf(angle: yawAngle, axis: SIMD3<Float>(0, 1, 0))
        entity.setOrientation(yawRotation * deckBaseOrientation, relativeTo: nil)
    }
}
