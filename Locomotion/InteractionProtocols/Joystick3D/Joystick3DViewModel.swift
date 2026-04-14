//
//  Joystick3DViewModel.swift
//  Locomotion
//
//  Created by Bekhruzjon Hakmirzaev on 14/04/26.
//

import SwiftUI
import simd
import RealityKit

/// Manages 3D joystick state: gesture input, bone animation, and velocity output.
///
/// Handles pinch-drag input normalization, per-frame bone tilt animation,
/// and writes normalized velocities to `InputViewModel.shared`.
@Observable @MainActor
final class Joystick3DViewModel {

    // MARK: - Model Configuration

    /// Bone tip translation in the model's local space (from Blender export).
    let boneTipOffset = SIMD3<Float>(0.0, 0.0, 0.1648348)

    /// Position of the invisible interaction sphere in the model's local space.
    let stickHitboxOffset = SIMD3<Float>(0.0, 0.38, 0.0)

    /// Scale applied to the 3D joystick model in the scene.
    let joystickScale: Float = 0.15

    /// Horizontal spacing between left and right joysticks (metres).
    let joystickSpacing: Float = 0.45

    /// Distance in front of the user (metres, negative Z = forward).
    let joystickDistance: Float = 0.5

    /// Vertical offset from eye level (metres, negative = below).
    let joystickHeight: Float = -0.3

    /// Radius of the invisible interaction sphere (metres).
    let stickHitboxRadius: Float = 0.06

    /// Metres of hand movement for full stick deflection.
    let dragScale: Float = 0.08

    /// Rotation offset for the left stick's input axes (radians).
    let leftStickInputRotation: Float = -.pi / 4

    /// Bone rest rotation baked by Blender (90° X-axis compensation).
    let restRotation = simd_quatf(
        real: 0.70710677,
        imag: SIMD3<Float>(0.70710677, 8.9488196e-08, 8.9488196e-08)
    )

    // MARK: - Bone Animation Values

    /// Left stick horizontal tilt angle (radians).
    var leftBoneX: Float = 0.0

    /// Left stick vertical tilt angle (radians).
    var leftBoneY: Float = 0.0

    /// Right stick horizontal tilt angle (radians).
    var rightBoneX: Float = 0.0

    // MARK: - Private State

    private let maxTilt: Float = 0.4
    private var leftCurrent: SIMD2<Float> = .zero
    private var rightCurrent: SIMD2<Float> = .zero

    // MARK: - Gesture Input

    /// Sets the left stick position from normalized pinch input.
    func setLeftTarget(axisX: Float, axisY: Float) {
        leftCurrent = SIMD2<Float>(axisX, axisY).clamped(magnitude: 1.0)
    }

    /// Sets the right stick position from normalized pinch input (X axis only).
    func setRightTarget(axisX: Float) {
        rightCurrent = SIMD2<Float>(axisX, 0).clamped(magnitude: 1.0)
    }

    /// Zeros the left stick on pinch release.
    func releaseLeft() {
        leftCurrent = .zero
    }

    /// Zeros the right stick on pinch release.
    func releaseRight() {
        rightCurrent = .zero
    }

    // MARK: - Frame Update

    /// Updates bone animation values and writes velocities to InputViewModel.
    func update(deltaTime: Float) {
        leftBoneX = leftCurrent.x * maxTilt
        leftBoneY = leftCurrent.y * maxTilt
        rightBoneX = rightCurrent.x * maxTilt

        InputViewModel.shared.leftStickX = Double(leftCurrent.x)
        InputViewModel.shared.leftStickY = Double(leftCurrent.y)
        InputViewModel.shared.rightStickX = Double(rightCurrent.x)
    }

    // MARK: - Hitbox Creation

    /// Creates an invisible interaction sphere for hand tracking.
    func makeStickHitbox(named name: String) -> ModelEntity {
        let radius = stickHitboxRadius / joystickScale

        var mat = UnlitMaterial()
        mat.color = .init(tint: UIColor(white: 1, alpha: 0.0))
        mat.blending = .transparent(opacity: .init(floatLiteral: 0))

        let sphere = ModelEntity(mesh: .generateSphere(radius: radius), materials: [mat])
        sphere.name = name
        sphere.position = stickHitboxOffset / joystickScale
        sphere.components.set(InputTargetComponent())
        sphere.generateCollisionShapes(recursive: false)

        return sphere
    }

    // MARK: - Bone Animation

    /// Applies tilt rotation to the joystick model's armature bone.
    func applyBoneTilt(to model: ModelEntity, tiltX: Float, tiltZ: Float) {
        let tiltAngle = sqrt(tiltX * tiltX + tiltZ * tiltZ)
        let tiltAxis = tiltAngle > 0.001
            ? SIMD3<Float>(tiltZ, 0, -tiltX) / tiltAngle
            : SIMD3<Float>(0, 0, 1)

        let bonePose = Transform(
            scale: .one,
            rotation: restRotation * simd_quatf(angle: tiltAngle, axis: tiltAxis),
            translation: boneTipOffset
        )

        if var skeletal = model.components[SkeletalPosesComponent.self],
           var pose = skeletal.poses.first {
            pose.jointTransforms = JointTransforms([bonePose])
            skeletal.poses[skeletal.poses.startIndex] = pose
            model.components.set(skeletal)
        }
    }
}

// MARK: - SIMD2 Magnitude Clamping

extension SIMD2 where Scalar == Float {
    /// Clamps the vector's magnitude to preserve direction within a unit circle.
    func clamped(magnitude: Float) -> SIMD2<Float> {
        let len = sqrt(x * x + y * y)
        return len > magnitude ? self / len * magnitude : self
    }
}
