//
//  HandSkeletonData.swift
//  Extracting files
//

import ARKit

/// Shared snapshot of the latest hand-tracking state.
/// All joint matrices are in ARKit world space (`originFromAnchor * anchorFromJoint`).
@Observable
class HandSkeletonData {

    var isLeftPinch: Bool = false
    var isRightPinch: Bool = false

    var isLeftTracked: Bool = false
    var isRightTracked: Bool = false

    var leftThumbTip = simd_float4x4()
    var rightThumbTip = simd_float4x4()

    var leftMiddleTip = simd_float4x4()
    var rightMiddleTip = simd_float4x4()

    var leftIndexKnuckle = simd_float4x4()
    var rightIndexKnuckle = simd_float4x4()

    var leftThumbKnuckle = simd_float4x4()
    var rightThumbKnuckle = simd_float4x4()
}

extension simd_float4x4 {
    var position: SIMD3<Float> {
        SIMD3(columns.3.x, columns.3.y, columns.3.z)
    }
}
