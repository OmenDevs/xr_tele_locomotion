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
            case .left:  skeletonData?.isLeftTracked  = false
            case .right: skeletonData?.isRightTracked = false
            }
            return
        }

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
            if let tip = thumbTip { skeletonData?.leftThumbTip = tip }
            if let tip = middleTip { skeletonData?.leftMiddleTip = tip }
            if let tip = middleKnuckle { skeletonData?.leftMiddleKnuckle = tip }
            if let tip = wrist { skeletonData?.leftWrist = tip }
            skeletonData?.isLeftTracked = true
        case .right:
            if let tip = thumbTip { skeletonData?.rightThumbTip = tip }
            if let tip = middleTip { skeletonData?.rightMiddleTip = tip }
            if let tip = middleKnuckle { skeletonData?.rightMiddleKnuckle = tip }
            if let tip = wrist { skeletonData?.rightWrist = tip }
            skeletonData?.isRightTracked = true
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
