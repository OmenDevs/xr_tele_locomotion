//
//  TurnGestureProcessor.swift
//  Locomotion
//
//  Pure-logic processor for the turning gesture.
//  Reads joint positions from HandSkeletonData, computes normalized angular velocity.
//  No SwiftUI, no RealityKit.
//

import Foundation
import simd

// MARK: - Joint Positions

/// World-space positions of the three joints used by the turn gesture.
struct TurnJointPositions {
    let wrist: SIMD3<Float>
    let thumbTip: SIMD3<Float>
    let middleKnuckle: SIMD3<Float>
}

/// Computes a normalized turn angle from hand rotation around the wrist→thumbTip axis.
///
/// **Algorithm**:
/// 1. On pinch activation, capture the reference direction by projecting
///    `middleFingerKnuckle` onto the disk plane perpendicular to the wrist→thumbTip axis.
/// 2. Each frame, project `middleFingerKnuckle` again, compute the signed angle
///    from the reference direction to the current direction.
/// 3. Apply deadzone, clamp to ±maxAngle, and normalize to -1…+1.
@MainActor
final class TurnGestureProcessor {

    // MARK: - Tunable Constants

    /// Angles below this threshold are treated as zero (tremor suppression).
    static let deadzone: Float = 5.0 * .pi / 180.0       // 5° in radians

    /// Maximum angle for full-speed output. Angle is clamped to ±maxAngle.
    static let maxAngle: Float = 45.0 * .pi / 180.0      // 45° in radians

    /// Exponential smoothing factor applied to the raw angle (0 = frozen, 1 = instant).
    static let smoothingAlpha: Float = 0.2

    // MARK: - Internal State

    /// The reference direction captured on the first frame of activation.
    private var referenceDirection: SIMD3<Float>?

    /// Low-pass filtered angle for stable output.
    private var smoothedAngle: Float = 0.0

    /// Which hand activated first. Prevents switching mid-gesture.
    private var lockedHand: ActiveHand = .none

    // MARK: - Debug / Visualization Data

    /// Current signed angle in radians (pre-deadzone, pre-clamp). Useful for the visualizer.
    private(set) var rawAngle: Float = 0.0

    /// Current axis origin (thumbTip world position). Useful for the visualizer.
    private(set) var axisOrigin: SIMD3<Float> = .zero

    /// Current axis direction. Useful for the visualizer.
    private(set) var axisDirection: SIMD3<Float> = .init(0, 1, 0)

    /// Current reference direction in the plane. Useful for the visualizer.
    private(set) var currentReferenceDirection: SIMD3<Float>?

    /// Current finger projection direction in the plane. Useful for the visualizer.
    private(set) var currentFingerDirection: SIMD3<Float>?

    // MARK: - Public API

    /// Call once per frame. Reads pinch + joint data, writes to `state`.
    func update(skeletonData: HandSkeletonData, state: GestureInputState) {
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

    /// Resets internal state.  Call when gesture ends or interaction changes.
    func resetAll(state: GestureInputState) {
        resetState(state: state)
    }

    // MARK: - Hand Selection

    /// Determines which hand is active. Returns true if a hand is pinching.
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

    /// Core geometry: projects middleKnuckle onto the disk plane and computes the angle.
    private func computeTurnAngle(joints: TurnJointPositions, state: GestureInputState) {
        let axis = simd_normalize(joints.thumbTip - joints.wrist)
        let axisLen = simd_length(joints.thumbTip - joints.wrist)
        guard axisLen > 0.001 else { return }

        axisOrigin = joints.thumbTip
        axisDirection = axis

        // Project middleFingerKnuckle onto the disk plane at thumbTip.
        let toKnuckle = joints.middleKnuckle - joints.thumbTip
        let projOnAxis = simd_dot(toKnuckle, axis) * axis
        let projOnPlane = toKnuckle - projOnAxis

        guard simd_length(projOnPlane) > 0.001 else { return }

        let currentDir = simd_normalize(projOnPlane)
        currentFingerDirection = currentDir

        // Capture reference on first active frame.
        if referenceDirection == nil {
            referenceDirection = currentDir
            currentReferenceDirection = currentDir
            smoothedAngle = 0
            rawAngle = 0
            state.normalizedTurnAngle = 0
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

        // Signed angle via atan2.
        let dotVal = simd_clamp(simd_dot(refDir, currentDir), -1.0, 1.0)
        let crossVal = simd_cross(refDir, currentDir)
        let signedSin = simd_dot(crossVal, axis)
        let angle = atan2(signedSin, dotVal)

        // Exponential smoothing to suppress tracking noise.
        smoothedAngle = Self.smoothingAlpha * angle + (1.0 - Self.smoothingAlpha) * smoothedAngle
        rawAngle = smoothedAngle

        // Deadzone.
        guard abs(smoothedAngle) >= Self.deadzone else {
            state.normalizedTurnAngle = 0.0
            return
        }

        // Clamp and normalize to -1…+1.
        let clampedAngle = simd_clamp(smoothedAngle, -Self.maxAngle, Self.maxAngle)
        state.normalizedTurnAngle = Double(clampedAngle / Self.maxAngle)
    }

    // MARK: - Reset

    private func resetState(state: GestureInputState) {
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

    /// Extracts world-space positions for the three joints from the skeleton data.
    private func jointPositions(
        for hand: ActiveHand,
        skeletonData: HandSkeletonData
    ) -> TurnJointPositions {
        let wristMatrix: simd_float4x4
        let thumbTipMatrix: simd_float4x4
        let middleKnuckleMatrix: simd_float4x4

        switch hand {
        case .left:
            wristMatrix = skeletonData.leftWrist
            thumbTipMatrix = skeletonData.leftThumbTip
            middleKnuckleMatrix = skeletonData.leftMiddleKnuckle
        case .right, .none:
            wristMatrix = skeletonData.rightWrist
            thumbTipMatrix = skeletonData.rightThumbTip
            middleKnuckleMatrix = skeletonData.rightMiddleKnuckle
        }

        return TurnJointPositions(
            wrist: position(from: wristMatrix),
            thumbTip: position(from: thumbTipMatrix),
            middleKnuckle: position(from: middleKnuckleMatrix)
        )
    }

    /// Extracts the translation column from a 4×4 transform matrix.
    private func position(from matrix: simd_float4x4) -> SIMD3<Float> {
        SIMD3<Float>(matrix.columns.3.x, matrix.columns.3.y, matrix.columns.3.z)
    }
}
