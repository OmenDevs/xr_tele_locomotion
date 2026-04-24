import Foundation
import simd

@Observable
class PinchInputViewModel {

    static let shared = PinchInputViewModel()

    var skeletonData: HandSkeletonData?

    let dragScale: Float = 0.08

    private var leftReferencePoint: SIMD3<Float>?
    private var rightReferencePoint: SIMD3<Float>?
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

    private func updateLeft(_ skeleton: HandSkeletonData) {
        let isPinching = skeleton.isLeftPinch

        if isPinching && !wasLeftPinching {
            let thumb = position(from: skeleton.leftThumbTip)
            let middle = position(from: skeleton.leftMiddleTip)
            leftReferencePoint = (thumb + middle) / 2
            wasLeftPinching = true
            print("left pinch: ACTIVE")
        }

        if !isPinching && wasLeftPinching {
            wasLeftPinching = false
            leftReferencePoint = nil
            InputViewModel.shared.leftStickX = 0
            InputViewModel.shared.leftStickY = 0
            print("left pinch: RELEASED")
            return
        }

        guard isPinching, let ref = leftReferencePoint else { return }

        let thumb = position(from: skeleton.leftThumbTip)
        let middle = position(from: skeleton.leftMiddleTip)
        let midpoint = (thumb + middle) / 2
        let delta = midpoint - ref

        let velocityX = (delta.x / dragScale).clamped(to: -1...1)
        let velocityY = (-delta.z / dragScale).clamped(to: -1...1)

        InputViewModel.shared.leftStickX = Double(velocityX)
        InputViewModel.shared.leftStickY = Double(velocityY)

        print(String(format: "left vel: %+.3f x  %+.3f y", velocityX, velocityY))
    }

    private func updateRight(_ skeleton: HandSkeletonData) {
        let isPinching = skeleton.isRightPinch

        if isPinching && !wasRightPinching {
            let thumb = position(from: skeleton.rightThumbTip)
            let middle = position(from: skeleton.rightMiddleTip)
            rightReferencePoint = (thumb + middle) / 2
            wasRightPinching = true
            print("right pinch: ACTIVE")
        }

        if !isPinching && wasRightPinching {
            wasRightPinching = false
            rightReferencePoint = nil
            InputViewModel.shared.rightStickX = 0
            print("right pinch: RELEASED")
            return
        }

        guard isPinching, let ref = rightReferencePoint else { return }

        let thumb = position(from: skeleton.rightThumbTip)
        let middle = position(from: skeleton.rightMiddleTip)
        let midpoint = (thumb + middle) / 2
        let delta = midpoint - ref

        let angularVelocity = (delta.x / dragScale).clamped(to: -1...1)

        InputViewModel.shared.rightStickX = Double(angularVelocity)

        print(String(format: "right vel: %+.3f angular", angularVelocity))
    }
}

extension Float {
    func clamped(to range: ClosedRange<Float>) -> Float {
        Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}
