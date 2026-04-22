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
            let anchor = update.anchor
            guard anchor.isTracked else { continue }
            updateSkeletonData(from: anchor)
        }
    }

    private func updateSkeletonData(from anchor: HandAnchor) {
        guard let skeleton = anchor.handSkeleton else { return }
        let anchorTransform = anchor.originFromAnchorTransform

        let thumbTip      = jointTransform(of: .thumbTip,
                                           in: skeleton,
                                           anchorTransform: anchorTransform)
        let middleTip     = jointTransform(of: .middleFingerTip,
                                           in: skeleton,
                                           anchorTransform: anchorTransform)
        let middleKnuckle = jointTransform(of: .middleFingerKnuckle,
                                           in: skeleton,
                                           anchorTransform: anchorTransform)
        let wrist         = jointTransform(of: .wrist,
                                           in: skeleton,
                                           anchorTransform: anchorTransform)

        switch anchor.chirality {
        case .left:
            skeletonData?.leftThumbTip      = thumbTip
            skeletonData?.leftMiddleTip     = middleTip
            skeletonData?.leftMiddleKnuckle = middleKnuckle
            skeletonData?.leftWrist         = wrist
        case .right:
            skeletonData?.rightThumbTip      = thumbTip
            skeletonData?.rightMiddleTip     = middleTip
            skeletonData?.rightMiddleKnuckle = middleKnuckle
            skeletonData?.rightWrist         = wrist
        }
    }

    private func jointTransform(of jointName: HandSkeleton.JointName,
                                in skeleton: HandSkeleton,
                                anchorTransform: simd_float4x4) -> simd_float4x4? {
        let joint = skeleton.joint(jointName)
        guard joint.isTracked else { return nil }
        return anchorTransform * joint.anchorFromJointTransform
    }
}
