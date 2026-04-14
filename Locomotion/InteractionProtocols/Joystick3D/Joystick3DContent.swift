//
//  Joystick3DContent.swift
//  Locomotion
//
//  Created by Bekhruzjon Hakmirzaev on 14/04/26.
//

import SwiftUI
import RealityKit

/// Provides reusable 3D joystick setup for RealityKit immersive spaces.
///
/// Use `addJoysticks(to:viewModel:)` in a RealityView make closure,
/// `handleFrameUpdate(scene:deltaTime:viewModel:)` in a SceneEvents.Update subscription,
/// and `.joystick3DGesture(viewModel:)` as a view modifier.
enum Joystick3DContent {

    /// Loads and positions two 3D joystick models with hitbox spheres.
    @MainActor
    static func addJoysticks(
        to content: RealityViewContent,
        viewModel: Joystick3DViewModel
    ) async {
        if let leftJS = try? await ModelEntity(named: "Joystick") {
            leftJS.name = "leftJoystick"
            leftJS.position = SIMD3<Float>(
                -viewModel.joystickSpacing,
                1.0 + viewModel.joystickHeight,
                -viewModel.joystickDistance
            )
            leftJS.scale = SIMD3<Float>(repeating: viewModel.joystickScale)
            leftJS.addChild(viewModel.makeStickHitbox(named: "leftStick"))
            content.add(leftJS)
        }

        if let rightJS = try? await ModelEntity(named: "Joystick") {
            rightJS.name = "rightJoystick"
            rightJS.position = SIMD3<Float>(
                viewModel.joystickSpacing,
                1.0 + viewModel.joystickHeight,
                -viewModel.joystickDistance
            )
            rightJS.scale = SIMD3<Float>(repeating: viewModel.joystickScale)
            rightJS.addChild(viewModel.makeStickHitbox(named: "rightStick"))
            content.add(rightJS)
        }
    }

    /// Handles per-frame joystick updates: axis values and bone animation.
    @MainActor
    static func handleFrameUpdate(
        scene: RealityKit.Scene,
        deltaTime: TimeInterval,
        viewModel: Joystick3DViewModel
    ) {
        viewModel.update(deltaTime: Float(deltaTime))

        if let leftJS = scene.findEntity(named: "leftJoystick") as? ModelEntity {
            viewModel.applyBoneTilt(to: leftJS, tiltX: viewModel.leftBoneX, tiltZ: -viewModel.leftBoneY)
        }
        if let rightJS = scene.findEntity(named: "rightJoystick") as? ModelEntity {
            viewModel.applyBoneTilt(to: rightJS, tiltX: viewModel.rightBoneX, tiltZ: 0)
        }
    }
}

// MARK: - 3D Joystick Gesture

extension View {
    /// Adds 3D joystick pinch-drag gesture handling targeting hitbox entities.
    func joystick3DGesture(viewModel: Joystick3DViewModel) -> some View {
        self.gesture(
            DragGesture(minimumDistance: 0.01)
                .targetedToEntity(where: .has(InputTargetComponent.self))
                .onChanged { value in
                    let name = value.entity.name
                    let currentPos = value.convert(value.location3D, from: .local, to: .scene)
                    let startPos = value.convert(value.startLocation3D, from: .local, to: .scene)

                    let delta = SIMD3<Float>(
                        Float(currentPos.x - startPos.x),
                        Float(currentPos.y - startPos.y),
                        Float(currentPos.z - startPos.z)
                    )

                    let baseX = (delta.x / viewModel.dragScale).clamped(to: -1...1)
                    let baseY = (delta.z / viewModel.dragScale).clamped(to: -1...1)

                    switch name {
                    case "leftStick":
                        let cosAngle = cos(viewModel.leftStickInputRotation)
                        let sinAngle = sin(viewModel.leftStickInputRotation)
                        let rotatedX = (baseX * cosAngle - baseY * sinAngle).clamped(to: -1...1)
                        let rotatedY = (baseX * sinAngle + baseY * cosAngle).clamped(to: -1...1)
                        viewModel.setLeftTarget(axisX: rotatedX, axisY: -rotatedY)
                    case "rightStick":
                        viewModel.setRightTarget(axisX: baseX)
                    default:
                        break
                    }
                }
                .onEnded { value in
                    switch value.entity.name {
                    case "leftStick":  viewModel.releaseLeft()
                    case "rightStick": viewModel.releaseRight()
                    default: break
                    }
                }
        )
    }
}

// MARK: - Float Clamping

extension Float {
    /// Clamps the value to the given range.
    func clamped(to range: ClosedRange<Float>) -> Float {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
