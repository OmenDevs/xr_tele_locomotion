import Foundation
import simd

@Observable
class GestureInputViewModel {

    static let shared = GestureInputViewModel()

    let dragScale: Float = 0.16
    static let deadzone: Float = 0.01   // 1 cm

    private var lockedHand: ActiveHand = .none
    private var referencePoint: SIMD3<Float>?

    // Yaw-only basis on the XZ plane, captured at pinch start and held constant
    // for the gesture so the input frame doesn't drift with live head rotation.
    private var frameRight: SIMD3<Float> = SIMD3<Float>(1, 0, 0)
    private var frameForward: SIMD3<Float> = SIMD3<Float>(0, 0, -1)

    // MARK: - Visualization data

    /// Pinch origin in world space. `nil` while no pinch is active.
    private(set) var dragOrigin: SIMD3<Float>?

    /// Current cursor position in world space, clamped to the drag circle radius.
    /// Sits on the same horizontal plane (y) as `dragOrigin`.
    private(set) var cursorPoint: SIMD3<Float>?

    /// Yaw (radians, around +Y) of the captured user-local frame. `nil` while no pinch is active.
    private(set) var frozenYaw: Float?

    // MARK: - Update

    func update(skeletonData: HandSkeletonData,
                headTransform: simd_float4x4?,
                state: InputViewModel) {
        // First-pinch wins: acquire lock on the first frame either hand pinches.
        // Left is checked before right to match TurnGestureProcessor's priority,
        // so both processors converge on the same active hand.
        if lockedHand == .none {
            if skeletonData.isLeftPinch {
                acquireLock(.left,
                            thumb: skeletonData.leftThumbTip,
                            middle: skeletonData.leftMiddleTip,
                            headTransform: headTransform)
            } else if skeletonData.isRightPinch {
                acquireLock(.right,
                            thumb: skeletonData.rightThumbTip,
                            middle: skeletonData.rightMiddleTip,
                            headTransform: headTransform)
            }
        }

        switch lockedHand {
        case .none:
            return
        case .left:
            if skeletonData.isLeftPinch {
                drive(thumb: skeletonData.leftThumbTip,
                      middle: skeletonData.leftMiddleTip,
                      state: state)
            } else {
                release(state: state)
            }
        case .right:
            if skeletonData.isRightPinch {
                drive(thumb: skeletonData.rightThumbTip,
                      middle: skeletonData.rightMiddleTip,
                      state: state)
            } else {
                release(state: state)
            }
        }
    }

    private func acquireLock(_ hand: ActiveHand,
                             thumb: simd_float4x4,
                             middle: simd_float4x4,
                             headTransform: simd_float4x4?) {
        lockedHand = hand
        let mid = midpoint(thumb: thumb, middle: middle)
        referencePoint = mid
        dragOrigin = mid
        cursorPoint = mid
        captureFrame(headTransform: headTransform)
        let yawDeg = (frozenYaw ?? 0) * 180 / .pi
        let headStatus = headTransform == nil ? "no head" : "head ok"
        print(String(format: "%@ pinch: ACTIVE  fwd=(%.2f, %.2f, %.2f)  yaw=%+.1f°  [%@]",
                     hand == .left ? "left" : "right",
                     frameForward.x, frameForward.y, frameForward.z,
                     yawDeg, headStatus))
    }

    /// Capture a yaw-only basis on the XZ plane from the head pose.
    /// Falls back to world axes if no head transform is available.
    private func captureFrame(headTransform: simd_float4x4?) {
        guard let head = headTransform else {
            frameRight = SIMD3<Float>(1, 0, 0)
            frameForward = SIMD3<Float>(0, 0, -1)
            frozenYaw = 0
            return
        }
        // ARKit camera convention: device's local −Z points forward in world space.
        let forwardWorld = -SIMD3<Float>(head.columns.2.x, head.columns.2.y, head.columns.2.z)
        var forwardXZ = SIMD3<Float>(forwardWorld.x, 0, forwardWorld.z)
        let len = simd_length(forwardXZ)
        guard len > 1e-4 else {
            // Looking straight up/down; preserve previous frame defaults.
            frameRight = SIMD3<Float>(1, 0, 0)
            frameForward = SIMD3<Float>(0, 0, -1)
            frozenYaw = 0
            return
        }
        forwardXZ /= len
        // Right is forward × up in right-handed coords (with +Y up).
        let rightXZ = SIMD3<Float>(-forwardXZ.z, 0, forwardXZ.x)
        frameForward = forwardXZ
        frameRight = rightXZ
        // Yaw such that simd_quatf(angle: yaw, axis: +Y) maps local (0,0,-1) → frameForward.
        // Right-handed Y-rot of (0,0,-1) gives (-sin θ, 0, -cos θ); solve for θ.
        frozenYaw = atan2(-forwardXZ.x, -forwardXZ.z)
    }

    private func drive(thumb: simd_float4x4, middle: simd_float4x4, state: InputViewModel) {
        guard let ref = referencePoint else { return }
        let mid = midpoint(thumb: thumb, middle: middle)
        let delta = mid - ref

        // Project onto the frozen user-local basis: (right⋅delta, forward⋅delta).
        let planar = SIMD2<Float>(simd_dot(delta, frameRight),
                                  simd_dot(delta, frameForward))
        let radius = simd_length(planar)

        // Deadzone: sphere stays pinned at origin, no commands sent.
        guard radius >= Self.deadzone else {
            state.velocityX = 0
            state.velocityY = 0
            cursorPoint = ref
            return
        }

        // Circular clamp for cursor visualization.
        let clampedPlanar: SIMD2<Float> = radius > dragScale ? (planar / radius) * dragScale : planar

        // Remap [deadzone, dragScale] → [0, 1] so velocity starts from 0.
        let remappedRadius = (min(radius, dragScale) - Self.deadzone) / (dragScale - Self.deadzone)
        let direction = planar / radius
        let normalized = direction * remappedRadius
        state.velocityX = Double(normalized.x)
        state.velocityY = Double(normalized.y)

        // Reproject clamped planar back into world space using the frozen basis.
        let worldDelta = clampedPlanar.x * frameRight + clampedPlanar.y * frameForward
        cursorPoint = ref + worldDelta
    }

    private func release(state: InputViewModel) {
        state.velocityX = 0
        state.velocityY = 0
        lockedHand = .none
        referencePoint = nil
        dragOrigin = nil
        cursorPoint = nil
        frozenYaw = nil
        print("pinch: RELEASED")
    }

    private func midpoint(thumb: simd_float4x4, middle: simd_float4x4) -> SIMD3<Float> {
        (position(from: thumb) + position(from: middle)) / 2
    }

    private func position(from matrix: simd_float4x4) -> SIMD3<Float> {
        SIMD3(matrix.columns.3.x, matrix.columns.3.y, matrix.columns.3.z)
    }
}
