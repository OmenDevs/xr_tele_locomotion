//
//  HandSkeletonProvider.swift

import ARKit

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
            updateSkeletonData(from: update.anchor)
        }
    }

    private func updateSkeletonData(from anchor: HandAnchor) {
        guard anchor.isTracked, let skeleton = anchor.handSkeleton else {
            switch anchor.chirality {
            case .left:  skeletonData?.isLeftTracked = false
            case .right: skeletonData?.isRightTracked = false
            }
            skeletonData?.updatePinch(for: anchor.chirality)
            return
        }

        let anchorTransform = anchor.originFromAnchorTransform
        let joints = resolveJoints(from: skeleton, anchorTransform: anchorTransform)

        applyJoints(joints, for: anchor.chirality)
        skeletonData?.updatePinch(for: anchor.chirality)
    }

    private func resolveJoints(from skeleton: HandSkeleton,
                               anchorTransform: simd_float4x4) -> HandJoints {
        HandJoints(
            thumbTip: jointTransform(of: .thumbTip, in: skeleton, anchorTransform: anchorTransform),
            thumbKnuckle: jointTransform(of: .thumbKnuckle, in: skeleton, anchorTransform: anchorTransform),
            middleTip: jointTransform(of: .middleFingerTip, in: skeleton, anchorTransform: anchorTransform),
            indexKnuckle: jointTransform(of: .indexFingerKnuckle, in: skeleton, anchorTransform: anchorTransform)
        )
    }

    private func applyJoints(_ joints: HandJoints, for chirality: HandAnchor.Chirality) {
        switch chirality {
        case .left:  applyJointsToLeft(joints)
        case .right: applyJointsToRight(joints)
        }
    }

    private func applyJointsToLeft(_ joints: HandJoints) {
        if let val = joints.thumbTip { skeletonData?.leftThumbTip = val }
        if let val = joints.thumbKnuckle { skeletonData?.leftThumbKnuckle = val }
        if let val = joints.middleTip { skeletonData?.leftMiddleTip = val }
        if let val = joints.indexKnuckle { skeletonData?.leftIndexKnuckle = val }
        skeletonData?.isLeftTracked = true
    }

    private func applyJointsToRight(_ joints: HandJoints) {
        if let val = joints.thumbTip { skeletonData?.rightThumbTip = val }
        if let val = joints.thumbKnuckle { skeletonData?.rightThumbKnuckle = val }
        if let val = joints.middleTip { skeletonData?.rightMiddleTip = val }
        if let val = joints.indexKnuckle { skeletonData?.rightIndexKnuckle = val }
        skeletonData?.isRightTracked = true
    }

    private struct HandJoints {
        var thumbTip: simd_float4x4?
        var thumbKnuckle: simd_float4x4?
        var middleTip: simd_float4x4?
        var indexKnuckle: simd_float4x4?
    }

    private func jointTransform(of jointName: HandSkeleton.JointName,
                                in skeleton: HandSkeleton,
                                anchorTransform: simd_float4x4) -> simd_float4x4? {
        let joint = skeleton.joint(jointName)
        guard joint.isTracked else { return nil }
        return anchorTransform * joint.anchorFromJointTransform
    }
}
