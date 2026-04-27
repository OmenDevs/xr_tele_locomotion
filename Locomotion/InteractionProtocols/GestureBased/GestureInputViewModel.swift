import Foundation
import simd

@Observable
class GestureInputViewModel {

    static let shared = GestureInputViewModel()

    let dragScale: Float = 0.16

    private var lockedHand: ActiveHand = .none
    private var referencePoint: SIMD3<Float>?

    // MARK: - Visualization data

    /// Pinch origin in world space. `nil` while no pinch is active.
    private(set) var dragOrigin: SIMD3<Float>?

    /// Current cursor position in world space, clamped to the drag circle radius.
    /// Sits on the same horizontal plane (y) as `dragOrigin`.
    private(set) var cursorPoint: SIMD3<Float>?

    // MARK: - Update

    func update(skeletonData: HandSkeletonData, state: GestureInputState) {
        // First-pinch wins: acquire lock on the first frame either hand pinches.
        // Left is checked before right to match TurnGestureProcessor's priority,
        // so both processors converge on the same active hand.
        if lockedHand == .none {
            if skeletonData.isLeftPinch {
                acquireLock(.left,
                            thumb: skeletonData.leftThumbTip,
                            middle: skeletonData.leftMiddleTip)
            } else if skeletonData.isRightPinch {
                acquireLock(.right,
                            thumb: skeletonData.rightThumbTip,
                            middle: skeletonData.rightMiddleTip)
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

    private func acquireLock(_ hand: ActiveHand, thumb: simd_float4x4, middle: simd_float4x4) {
        lockedHand = hand
        let mid = midpoint(thumb: thumb, middle: middle)
        referencePoint = mid
        dragOrigin = mid
        cursorPoint = mid
        print("\(hand == .left ? "left" : "right") pinch: ACTIVE")
    }

    private func drive(thumb: simd_float4x4, middle: simd_float4x4, state: GestureInputState) {
        guard let ref = referencePoint else { return }
        let mid = midpoint(thumb: thumb, middle: middle)
        let delta = mid - ref

        // Project onto the drag plane: (worldX, -worldZ) → (velX, velY).
        let planar = SIMD2<Float>(delta.x, -delta.z)
        let radius = simd_length(planar)

        // Circular clamp: saturate at radius `dragScale`.
        let normalized: SIMD2<Float>
        let clampedPlanar: SIMD2<Float>
        if radius > dragScale {
            let unit = planar / radius
            normalized = unit
            clampedPlanar = unit * dragScale
        } else {
            normalized = planar / dragScale
            clampedPlanar = planar
        }

        state.dragX = Double(normalized.x)
        state.dragY = Double(normalized.y)

        // Reproject clamped planar back to world XZ (planar.y = -delta.z).
        let worldDelta = SIMD3<Float>(clampedPlanar.x, 0, -clampedPlanar.y)
        cursorPoint = ref + worldDelta

        print(String(format: "drag vel: %+.3f x  %+.3f y", normalized.x, normalized.y))
    }

    private func release(state: GestureInputState) {
        state.dragX = 0
        state.dragY = 0
        lockedHand = .none
        referencePoint = nil
        dragOrigin = nil
        cursorPoint = nil
        print("pinch: RELEASED")
    }

    private func midpoint(thumb: simd_float4x4, middle: simd_float4x4) -> SIMD3<Float> {
        (position(from: thumb) + position(from: middle)) / 2
    }

    private func position(from matrix: simd_float4x4) -> SIMD3<Float> {
        SIMD3(matrix.columns.3.x, matrix.columns.3.y, matrix.columns.3.z)
    }
}
