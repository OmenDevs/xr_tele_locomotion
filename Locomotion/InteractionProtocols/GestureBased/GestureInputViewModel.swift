import Foundation
import simd

@Observable
class GestureInputViewModel {

    static let shared = GestureInputViewModel()

    let dragScale: Float = 0.08

    private var lockedHand: ActiveHand = .none
    private var referencePoint: SIMD3<Float>?

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
        referencePoint = midpoint(thumb: thumb, middle: middle)
        print("\(hand == .left ? "left" : "right") pinch: ACTIVE")
    }

    private func drive(thumb: simd_float4x4, middle: simd_float4x4, state: GestureInputState) {
        guard let ref = referencePoint else { return }
        let mid = midpoint(thumb: thumb, middle: middle)
        let delta = mid - ref

        let velocityX = (delta.x / dragScale).clamped(to: -1...1)
        let velocityY = (-delta.z / dragScale).clamped(to: -1...1)

        state.dragX = Double(velocityX)
        state.dragY = Double(velocityY)

        print(String(format: "drag vel: %+.3f x  %+.3f y", velocityX, velocityY))
    }

    private func release(state: GestureInputState) {
        state.dragX = 0
        state.dragY = 0
        lockedHand = .none
        referencePoint = nil
        print("pinch: RELEASED")
    }

    private func midpoint(thumb: simd_float4x4, middle: simd_float4x4) -> SIMD3<Float> {
        (position(from: thumb) + position(from: middle)) / 2
    }

    private func position(from matrix: simd_float4x4) -> SIMD3<Float> {
        SIMD3(matrix.columns.3.x, matrix.columns.3.y, matrix.columns.3.z)
    }
}
