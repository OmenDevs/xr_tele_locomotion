//
//  HandSkeletonProvider.swift

import ARKit

@MainActor
final class HandSkeletonProvider {

    private let arkitSession = ARKitSession()
    private let handTrackingProvider = HandTrackingProvider()
    var skeletonData: HandSkeletonData?

    func start() async {
        do {
            try await arkitSession.run([handTrackingProvider])
        } catch {
            print("Failed to start HandTrackingProvider: \(error)")
            return
        }

        for await update in handTrackingProvider.anchorUpdates {
            let anchor = update.anchor

            switch anchor.chirality {
            case .left:  skeletonData?.isLeftTracked  = anchor.isTracked
            case .right: skeletonData?.isRightTracked = anchor.isTracked
            }

            guard anchor.isTracked, let skeleton = anchor.handSkeleton else { continue }

            let isPinch = detectPinch(skeleton: skeleton)
            switch anchor.chirality {
            case .left:  skeletonData?.isLeftPinch  = isPinch
            case .right: skeletonData?.isRightPinch = isPinch
            }

            updateSkeletonData(from: anchor)
        }
    }

    private func updateSkeletonData(from anchor: HandAnchor) {
        guard let handSkeleton = anchor.handSkeleton else { return }
        let anchorTransform = anchor.originFromAnchorTransform
        let joints = resolveJoints(from: handSkeleton, anchorTransform: anchorTransform)
        applyJoints(joints, for: anchor.chirality)
    }

    private func resolveJoints(from skeleton: HandSkeleton,
                               anchorTransform: simd_float4x4) -> HandJoints {
        HandJoints(
            thumbTip: jointTransform(of: .thumbTip, in: skeleton, anchorTransform: anchorTransform),
            middleTip: jointTransform(of: .middleFingerTip, in: skeleton, anchorTransform: anchorTransform),
            thumbKnuckle: jointTransform(of: .thumbKnuckle, in: skeleton, anchorTransform: anchorTransform),
            indexKnuckle: jointTransform(of: .indexFingerKnuckle, in: skeleton, anchorTransform: anchorTransform)
        )
    }

    private func applyJoints(_ joints: HandJoints, for chirality: HandAnchor.Chirality) {
        switch chirality {
        case .left:
            skeletonData?.leftThumbTip = joints.thumbTip
            skeletonData?.leftMiddleTip = joints.middleTip
            skeletonData?.leftThumbKnuckle = joints.thumbKnuckle
            skeletonData?.leftIndexKnuckle = joints.indexKnuckle
        case .right:
            skeletonData?.rightThumbTip = joints.thumbTip
            skeletonData?.rightMiddleTip = joints.middleTip
            skeletonData?.rightThumbKnuckle = joints.thumbKnuckle
            skeletonData?.rightIndexKnuckle = joints.indexKnuckle
        }
    }

    private struct HandJoints {
        var thumbTip: simd_float4x4
        var middleTip: simd_float4x4
        var thumbKnuckle: simd_float4x4
        var indexKnuckle: simd_float4x4
    }
    private func jointTransform(of jointName: HandSkeleton.JointName,
                                in skeleton: HandSkeleton,
                                anchorTransform: simd_float4x4) -> simd_float4x4 {
        let joint = skeleton.joint(jointName)
        return anchorTransform * joint.anchorFromJointTransform
    }

    // This two take care of is pinching
    private func detectPinch(skeleton: HandSkeleton) -> Bool {
        let middleTip     = localPosition(of: skeleton.joint(.middleFingerTip))
        let thumbTip = localPosition(of: skeleton.joint(.thumbTip))
        let distance: Float = simd_length(middleTip - thumbTip)
        return distance < 0.02
    }
    private func localPosition(of joint: HandSkeleton.Joint) -> SIMD3<Float> {
        let transform = joint.anchorFromJointTransform
        return SIMD3<Float>(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)
    }
}
