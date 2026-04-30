import Foundation
import simd
import RealityKit

@Observable
class PinchInputViewModel {

    static let shared = PinchInputViewModel()

    var skeletonData: HandSkeletonData?

    /// Deck entity. Its orientation defines "forward" for the pinch gesture.
    /// Hand movement is rotated into the deck's local axes before becoming velocity.
    /// When nil, the gesture falls back to world-space axes.
    var deck: Entity?

    var joystickHandle: Entity?
    var joystickRestPosition: SIMD3<Float>?
    var leverHandle: Entity?
    var leverRestPosition: SIMD3<Float>?

    let dragScale: Float = 0.16

    private var leftPinchStartPosition: SIMD3<Float>?
    private var rightPinchStartPosition: SIMD3<Float>?
    private var wasLeftPinching: Bool = false
    private var wasRightPinching: Bool = false

    func update() {
        guard let skeleton = skeletonData else { return }

        updateLeft(skeleton)
        updateRight(skeleton)
    }

    private func position(from matrix: simd_float4x4) -> SIMD3<Float> {
        SIMD3(matrix.columns.3.x, matrix.columns.3.y, matrix.columns.3.z)
    }

    /// Re-expresses a world-space movement vector in the deck's local axes.
    /// Same vector, different coordinate system.
    /// Falls back to world axes if `deck` is not set.
    private func convertedToDeckFrame(_ worldMovement: SIMD3<Float>) -> SIMD3<Float> {
        guard let deck else { return worldMovement }
        let local = deck.orientation(relativeTo: nil).inverse.act(worldMovement)
              return local
    }

    private func updateLeft(_ skeleton: HandSkeletonData) {
        let isPinching = skeleton.isLeftPinch

        if isPinching && !wasLeftPinching {
            let thumb = position(from: skeleton.leftThumbTip)
            let middle = position(from: skeleton.leftMiddleTip)
            leftPinchStartPosition = (thumb + middle) / 2
            wasLeftPinching = true
            print("left pinch: ACTIVE")
        }

        if !isPinching && wasLeftPinching {
            wasLeftPinching = false
            leftPinchStartPosition = nil
            InputViewModel.shared.velocityX = 0
            InputViewModel.shared.velocityY = 0
            print("left pinch: RELEASED")
            return
        }

        guard isPinching, let pinchStart = leftPinchStartPosition else { return }

        let thumb = position(from: skeleton.leftThumbTip)
        let middle = position(from: skeleton.leftMiddleTip)
        let midpoint = (thumb + middle) / 2
        let pinchMovement = convertedToDeckFrame(midpoint - pinchStart)

        let velocityX = (-pinchMovement.x / dragScale).clamped(to: -1...1)
        let velocityY = (-pinchMovement.y / dragScale).clamped(to: -1...1)

        InputViewModel.shared.velocityX = Double(velocityX)
        InputViewModel.shared.velocityY = Double(velocityY)

        print(String(format: "left vel: %+.3f x  %+.3f y", velocityX, velocityY))
    }

    private func updateRight(_ skeleton: HandSkeletonData) {
        let isPinching = skeleton.isRightPinch

        if isPinching && !wasRightPinching {
            let thumb = position(from: skeleton.rightThumbTip)
            let middle = position(from: skeleton.rightMiddleTip)
            rightPinchStartPosition = (thumb + middle) / 2
            wasRightPinching = true
            print("right pinch: ACTIVE")
        }

        if !isPinching && wasRightPinching {
            wasRightPinching = false
            rightPinchStartPosition = nil
            InputViewModel.shared.angularVelocity = 0
            print("right pinch: RELEASED")
            return
        }

        guard isPinching, let pinchStart = rightPinchStartPosition else { return }

        let thumb = position(from: skeleton.rightThumbTip)
        let middle = position(from: skeleton.rightMiddleTip)
        let midpoint = (thumb + middle) / 2
        let pinchMovement = convertedToDeckFrame(midpoint - pinchStart)

        let angularVelocity = (-pinchMovement.x / dragScale).clamped(to: -1...1)

        InputViewModel.shared.angularVelocity = Double(angularVelocity)

        print(String(format: "right vel: %+.3f angular", angularVelocity))
    }
}

extension Float {
    func clamped(to range: ClosedRange<Float>) -> Float {
        Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}
