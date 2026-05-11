import SwiftUI
import RealityKit
import RealityKitContent

struct Joystick3DView: View {
    @State private var frameSubscription: EventSubscription?
    @State private var handSkeletonProvider = HandSkeletonProvider()
    @State private var deckBaseOrientation: simd_quatf = .init(ix: 0, iy: 0, iz: 0, r: 1)
    @State private var manipulationSubscriptions: [EventSubscription] = []
    @Environment(HandSkeletonData.self) private var skeletonData

    var body: some View {
        RealityView { content in
            handSkeletonProvider.skeletonData = skeletonData
            PinchInputViewModel.shared.skeletonData = skeletonData
            Task { await handSkeletonProvider.start() }

            if let deck = try? await Entity(named: "joystick3d", in: realityKitContentBundle) {
                deck.position = SIMD3<Float>(0, 0.7, -0.5)
                content.add(deck)
                let bounds = deck.visualBounds(relativeTo: deck)
                let extents = bounds.extents + SIMD3<Float>(0.1, 0.1, 0.1)
                let shape = ShapeResource.generateBox(size: extents)
                ManipulationComponent.configureEntity(
                    deck,
                    allowedInputTypes: .direct,
                    collisionShapes: [shape])
                if var manipulation = deck.components[ManipulationComponent.self] {
                    manipulation.releaseBehavior = .stay
                    manipulation.dynamics.scalingBehavior = .none
                    deck.components.set(manipulation)
                }
                deckBaseOrientation = deck.orientation(relativeTo: nil)
                manipulationSubscriptions.append(
                    content.subscribe(to: ManipulationEvents.DidUpdateTransform.self, on: deck) { event in
                        let current = event.entity.orientation(relativeTo: nil)
                        let delta = current * deckBaseOrientation.inverse
                        let yaw = atan2(
                            2.0 * (delta.real * delta.imag.y + delta.imag.x * delta.imag.z),
                            1.0 - 2.0 * (delta.imag.y * delta.imag.y + delta.imag.z * delta.imag.z)
                        )
                        event.entity.setOrientation(
                            simd_quatf(angle: yaw, axis: [0, 1, 0]) * deckBaseOrientation,
                            relativeTo: nil
                        )
                    }
                )
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
}
