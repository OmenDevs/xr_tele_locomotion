//
//  HandSkeletonData.swift
//  Extracting files
//
//  Observable shared state fed by HandSkeletonProvider every frame.
//  Each property holds the world-space 4x4 transform of the joint:
//    - position: .columns.3.xyz
//    - rotation: upper-left 3x3 (columns 0, 1, 2)
//

import ARKit

@Observable
class HandSkeletonData {
    var leftThumbTip: simd_float4x4?
    var rightThumbTip: simd_float4x4?

    var leftMiddleTip: simd_float4x4?
    var rightMiddleTip: simd_float4x4?

    var leftMiddleKnuckle: simd_float4x4?
    var rightMiddleKnuckle: simd_float4x4?

    var leftWrist: simd_float4x4?
    var rightWrist: simd_float4x4?
}
