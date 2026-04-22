//
//  HandSkeletonData.swift
//  Extracting files
//
//  Observable shared state fed by HandSkeletonProvider every frame.
//  Keeps two dictionaries of world-space joint transforms (one per hand).
//

import SwiftUI
import ARKit

@Observable
class HandSkeletonData {
    var leftJoints: [HandSkeleton.JointName: simd_float4x4] = [:]
    var rightJoints: [HandSkeleton.JointName: simd_float4x4] = [:]

    func worldPosition(_ joint: HandSkeleton.JointName, chirality: HandAnchor.Chirality) -> SIMD3<Float>? {
        let dict = (chirality == .left) ? leftJoints : rightJoints
        guard let jointsDictionary = dict[joint] else { return nil }
        return SIMD3<Float>(jointsDictionary.columns.3.x, jointsDictionary.columns.3.y, jointsDictionary.columns.3.z)
    }
}
