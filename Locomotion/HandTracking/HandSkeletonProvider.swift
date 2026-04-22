//
//  HandSkeletonProvider.swift
//  Extracting files
//
//  The ARKit half of the extraction.
//
//  - Runs an ARKitSession with a HandTrackingProvider.
//  - For every HandAnchor update, reads every joint's
//    `anchorFromJointTransform`, composes it with
//    `originFromAnchorTransform` to get world-space, and writes the
//    result into HandSkeletonData.
//  - Also runs a simple fist heuristic (middle-finger tip closer to
//    the wrist than the middle-finger knuckle).
//  - If a visualizer is attached, forwards joint transforms to it so
//    per-joint spheres follow the hand.
//
//  Nothing here is RealityKit-dependent; you can strip the visualizer
//  block out entirely if you only want data.
//

import ARKit
import simd

@MainActor
final class HandSkeletonProvider {

    private let arkitSession = ARKitSession()
    private let handTrackingProvider = HandTrackingProvider()

    weak var skeletonData: HandSkeletonData?

    func start() async {
        do {
            try await arkitSession.run([handTrackingProvider])
        } catch {
            print("Failed to start HandTrackingProvider: \(error)")
            return
        }

        for await update in handTrackingProvider.anchorUpdates {
            let anchor = update.anchor
            guard anchor.isTracked, let skeleton = anchor.handSkeleton else { continue }

            let anchorTransform = anchor.originFromAnchorTransform
            var joints: [HandSkeleton.JointName: simd_float4x4] = [:]
            joints.reserveCapacity(HandSkeleton.JointName.allCases.count)

            for jointName in HandSkeleton.JointName.allCases {
                let joint = skeleton.joint(jointName)
                guard joint.isTracked else { continue }
                joints[jointName] = anchorTransform * joint.anchorFromJointTransform
            }

            let isFist = detectFist(skeleton: skeleton)

            switch anchor.chirality {
            case .left:
                skeletonData?.leftJoints = joints
                skeletonData?.isLeftFist = isFist
            case .right:
                skeletonData?.rightJoints = joints
                skeletonData?.isRightFist = isFist
            }
        }
    }

    private func detectFist(skeleton: HandSkeleton) -> Bool {
        let wrist         = localPosition(of: skeleton.joint(.wrist))
        let middleTip     = localPosition(of: skeleton.joint(.middleFingerTip))
        let middleKnuckle = localPosition(of: skeleton.joint(.middleFingerKnuckle))

        return simd_length(middleTip - wrist) < simd_length(middleKnuckle - wrist)
    }

    private func localPosition(of joint: HandSkeleton.Joint) -> SIMD3<Float> {
        let anchorJoint = joint.anchorFromJointTransform
        return SIMD3<Float>(anchorJoint.columns.3.x, anchorJoint.columns.3.y, anchorJoint.columns.3.z)
    }
}
