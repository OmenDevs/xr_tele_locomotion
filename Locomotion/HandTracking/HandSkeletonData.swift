//
//  HandSkeletonData.swift
//  Extracting files
//
//  Observable shared state fed by HandSkeletonProvider every frame.
//  Keeps two dictionaries of world-space joint transforms (one per
//  hand) plus convenience flags like isLeftFist / isRightFist. Add
//  more derived gestures here as you need them.
//

import SwiftUI
import ARKit

@Observable
class HandSkeletonData {
    var isLeftFist: Bool = false
    var isRightFist: Bool = false

    /// World-space transforms keyed by joint name. Empty until the
    /// corresponding hand is tracked at least once.
    var leftJoints: [HandSkeleton.JointName: simd_float4x4] = [:]
    var rightJoints: [HandSkeleton.JointName: simd_float4x4] = [:]

    func worldPosition(_ joint: HandSkeleton.JointName, chirality: HandAnchor.Chirality) -> SIMD3<Float>? {
        let dict = (chirality == .left) ? leftJoints : rightJoints
        guard let jointsDictionary = dict[joint] else { return nil }
        return SIMD3<Float>(jointsDictionary.columns.3.x, jointsDictionary.columns.3.y, jointsDictionary.columns.3.z)
    }
}
