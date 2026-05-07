//
//  TurnGestureProcessor.swift
//  Locomotion
//
//  Created by Bekhruzjon Hakmirzaev on 23/04/26.
//

import Foundation
import simd

// MARK: - Joint Positions

struct TurnJointPositions {
    let thumbKnuckle: SIMD3<Float>
    let thumbTip: SIMD3<Float>
    let indexKnuckle: SIMD3<Float>
}

/// Computes a normalized turn angle from hand rotation around the thumbKnuckle→thumbTip axis.
@MainActor
final class TurnGestureProcessor {

    // MARK: - Tunable Constants

    static let deadzone: Float = 8.0 * .pi / 180.0    // 8°
    static let maxAngle: Float = 45.0 * .pi / 180.0   // 45°
    static let smoothingAlpha: Float = 0.2

    // MARK: - Internal State

    private var referenceDirection: SIMD3<Float>?
    private var smoothedAngle: Float = 0.0
    private var lockedHand: ActiveHand = .none

    // MARK: - Visualization Data

    /// Pre-deadzone signed angle in radians.
    private(set) var rawAngle: Float = 0.0
    /// Axis origin (thumbTip world position).
    private(set) var axisOrigin: SIMD3<Float> = .zero
    /// Rotation axis direction.
    private(set) var axisDirection: SIMD3<Float> = .init(0, 1, 0)
    /// Reference direction in the disk plane, captured on activation.
    private(set) var currentReferenceDirection: SIMD3<Float>?
    /// Current finger projection direction in the disk plane.
    private(set) var currentFingerDirection: SIMD3<Float>?

    // MARK: - Public API

    /// Call once per frame.
    func update(skeletonData: HandSkeletonData, state: InputViewModel) {
        let isActive = resolveActiveHand(skeletonData: skeletonData)

        if !isActive {
            if state.isActive { resetState(state: state) }
            return
        }

        state.isActive = true
        state.activeHand = lockedHand

        let joints = jointPositions(for: lockedHand, skeletonData: skeletonData)
        computeTurnAngle(joints: joints, state: state)
    }

    /// Resets all gesture state.
    func resetAll(state: InputViewModel) {
        resetState(state: state)
    }

    // MARK: - Hand Selection

    private func resolveActiveHand(skeletonData: HandSkeletonData) -> Bool {
        let leftPinching = skeletonData.isLeftPinch
        let rightPinching = skeletonData.isRightPinch

        // First pinch wins; lock to that hand until release.
        if lockedHand == .none {
            if leftPinching {
                lockedHand = .left
            } else if rightPinching {
                lockedHand = .right
            }
        }

        switch lockedHand {
        case .left:  return leftPinching
        case .right: return rightPinching
        case .none:  return false
        }
    }

    // MARK: - Turn Angle Computation

    private func computeTurnAngle(joints: TurnJointPositions, state: InputViewModel) {
        let axis = simd_normalize(joints.thumbTip - joints.thumbKnuckle)
        let axisLen = simd_length(joints.thumbTip - joints.thumbKnuckle)
        guard axisLen > 0.001 else { return }

        axisOrigin = joints.thumbTip
        axisDirection = axis

        let toKnuckle = joints.indexKnuckle - joints.thumbTip
        let projOnAxis = simd_dot(toKnuckle, axis) * axis
        let projOnPlane = toKnuckle - projOnAxis

        guard simd_length(projOnPlane) > 0.001 else { return }

        let currentDir = simd_normalize(projOnPlane)
        currentFingerDirection = currentDir

        if referenceDirection == nil {
            referenceDirection = currentDir
            currentReferenceDirection = currentDir
            smoothedAngle = 0
            rawAngle = 0
            state.angularVelocity = 0
            return
        }

        // Re-project stored reference onto the current plane so both vectors are coplanar.
        // The axis shifts slightly each frame as the hand moves; without this, the angle
        // is measured between vectors on different planes and produces wrong results.
        guard let storedRef = referenceDirection else { return }
        let refOnCurrentPlane = storedRef - simd_dot(storedRef, axis) * axis
        guard simd_length(refOnCurrentPlane) > 0.001 else { return }
        let refDir = simd_normalize(refOnCurrentPlane)
        currentReferenceDirection = refDir

        let dotVal = simd_clamp(simd_dot(refDir, currentDir), -1.0, 1.0)
        let crossVal = simd_cross(refDir, currentDir)
        let signedSin = simd_dot(crossVal, axis)
        let angle = atan2(signedSin, dotVal)

        // Exponential smoothing to suppress tracking noise.
        smoothedAngle = Self.smoothingAlpha * angle + (1.0 - Self.smoothingAlpha) * smoothedAngle
        rawAngle = smoothedAngle

        guard abs(smoothedAngle) >= Self.deadzone else {
            state.angularVelocity = 0.0
            return
        }

        let clampedAngle = simd_clamp(smoothedAngle, -Self.maxAngle, Self.maxAngle)
        let sign: Float = clampedAngle >= 0 ? 1.0 : -1.0
        let remapped = (abs(clampedAngle) - Self.deadzone) / (Self.maxAngle - Self.deadzone)
        state.angularVelocity = Double(sign * remapped)
    }

    // MARK: - Reset

    private func resetState(state: InputViewModel) {
        referenceDirection = nil
        currentReferenceDirection = nil
        currentFingerDirection = nil
        smoothedAngle = 0
        rawAngle = 0
        lockedHand = .none
        axisOrigin = .zero
        axisDirection = .init(0, 1, 0)
        state.reset()
    }

    // MARK: - Joint Extraction

    private func jointPositions(
        for hand: ActiveHand,
        skeletonData: HandSkeletonData
    ) -> TurnJointPositions {
        let thumbKnuckleMatrix: simd_float4x4
        let thumbTipMatrix: simd_float4x4
        let indexKnuckleMatrix: simd_float4x4

        switch hand {
        case .left:
            thumbKnuckleMatrix = skeletonData.leftThumbKnuckle
            thumbTipMatrix = skeletonData.leftThumbTip
            indexKnuckleMatrix = skeletonData.leftIndexKnuckle
        case .right, .none:
            thumbKnuckleMatrix = skeletonData.rightThumbKnuckle
            thumbTipMatrix = skeletonData.rightThumbTip
            indexKnuckleMatrix = skeletonData.rightIndexKnuckle
        }

        return TurnJointPositions(
            thumbKnuckle: position(from: thumbKnuckleMatrix),
            thumbTip: position(from: thumbTipMatrix),
            indexKnuckle: position(from: indexKnuckleMatrix)
        )
    }

    private func position(from matrix: simd_float4x4) -> SIMD3<Float> {
        SIMD3<Float>(matrix.columns.3.x, matrix.columns.3.y, matrix.columns.3.z)
    }
}
