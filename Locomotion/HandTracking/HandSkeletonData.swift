//
//  HandSkeletonData.swift
//  Extracting files
//

import ARKit

@Observable
class HandSkeletonData {
    var isLeftTracked: Bool = false
    var isRightTracked: Bool = false

    var leftThumbTip: simd_float4x4
    var rightThumbTip: simd_float4x4

    var leftMiddleTip: simd_float4x4
    var rightMiddleTip: simd_float4x4

    var leftMiddleKnuckle: simd_float4x4
    var rightMiddleKnuckle: simd_float4x4

    var leftWrist: simd_float4x4
    var rightWrist: simd_float4x4

    init() {
        self.leftThumbTip = matrix_identity_float4x4
        self.rightThumbTip = matrix_identity_float4x4
        self.leftMiddleTip = matrix_identity_float4x4
        self.rightMiddleTip = matrix_identity_float4x4
        self.leftMiddleKnuckle = matrix_identity_float4x4
        self.rightMiddleKnuckle = matrix_identity_float4x4
        self.leftWrist = matrix_identity_float4x4
        self.rightWrist = matrix_identity_float4x4
    }

    var leftPinchDistance: Float? {
        guard isLeftTracked else { return nil }
        return distance(between: leftThumbTip, and: leftMiddleTip)
    }
    var rightPinchDistance: Float? {
        guard isRightTracked else { return nil }
        return distance(between: rightThumbTip, and: rightMiddleTip)
    }
    var smoothedLeftPinchDistance: Float = 0
    var smoothedRightPinchDistance: Float = 0
    private static let smoothAlpha: Float = 0.4

    var isLeftPinch: Bool = false
    var isRightPinch: Bool = false

    private static let pinchEnterThreshold: Float = 0.02   // engage  at 1 cm
    private static let pinchExitThreshold: Float = 0.03   // release at 3 cm

    func updatePinch(for chirality: HandAnchor.Chirality) {
        switch chirality {
        case .left:
            guard isLeftTracked, let rawDistance = leftPinchDistance else {
                isLeftPinch = false
                return
            }
            smoothedLeftPinchDistance = applyEMA(
                newValue: rawDistance,
                previousEMA: self.smoothedLeftPinchDistance,
                alpha: Self.smoothAlpha)
            if isLeftPinch {
                if smoothedLeftPinchDistance > Self.pinchExitThreshold { isLeftPinch = false }
            } else {
                if smoothedLeftPinchDistance < Self.pinchEnterThreshold { isLeftPinch = true }
            }
        case .right:
            guard isRightTracked, let rawDistance = rightPinchDistance else {
                isRightPinch = false
                return
            }
            smoothedRightPinchDistance = applyEMA(
                newValue: rawDistance,
                previousEMA: self.smoothedRightPinchDistance,
                alpha: Self.smoothAlpha)
            if isRightPinch {
                if smoothedRightPinchDistance > Self.pinchExitThreshold { isRightPinch = false }
            } else {
                if smoothedRightPinchDistance < Self.pinchEnterThreshold { isRightPinch = true }
            }
        }
    }

    private func distance(between aAnchor: simd_float4x4, and bAnchor: simd_float4x4) -> Float {
        let aPosition = SIMD3<Float>(aAnchor.columns.3.x, aAnchor.columns.3.y, aAnchor.columns.3.z)
        let bPosition = SIMD3<Float>(bAnchor.columns.3.x, bAnchor.columns.3.y, bAnchor.columns.3.z)
        return simd_distance(aPosition, bPosition)
    }

    private func applyEMA(newValue: Float, previousEMA: Float, alpha: Float) -> Float {
        return alpha * newValue + (1 - alpha) * previousEMA
    }
}
