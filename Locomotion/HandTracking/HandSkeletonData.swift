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

    var isLeftPinch: Bool {
        guard isLeftTracked, let leftPinchDistance else { return false }
        return leftPinchDistance < 0.03
    }

    var isRightPinch: Bool {
        guard isRightTracked, let rightPinchDistance else { return false }
        return rightPinchDistance < 0.03
    }

    private func distance(between aAnchor: simd_float4x4, and bAnchor: simd_float4x4) -> Float {
        let aPosition = SIMD3<Float>(aAnchor.columns.3.x, aAnchor.columns.3.y, aAnchor.columns.3.z)
        let bPosition = SIMD3<Float>(bAnchor.columns.3.x, bAnchor.columns.3.y, bAnchor.columns.3.z)
        return simd_distance(aPosition, bPosition)
    }
}
