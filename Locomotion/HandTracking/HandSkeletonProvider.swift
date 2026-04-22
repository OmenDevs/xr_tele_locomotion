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
            guard anchor.isTracked, let skeleton = anchor.handSkeleton else { continue }

            let anchorTransform = anchor.originFromAnchorTransform
            var joints: [HandSkeleton.JointName: simd_float4x4] = [:]
            joints.reserveCapacity(HandSkeleton.JointName.allCases.count)

            for jointName in HandSkeleton.JointName.allCases {
                let joint = skeleton.joint(jointName)
                guard joint.isTracked else { continue }
                joints[jointName] = anchorTransform * joint.anchorFromJointTransform

                if jointName == .thumbTip || jointName == .indexFingerTip {
                        let ttt = joints[jointName]!          // safe: we just assigned it above
                        let pos = SIMD3<Float>(ttt.columns.3.x, ttt.columns.3.y, ttt.columns.3.z)
                        print("[\(anchor.chirality)] \(jointName): \(pos)")
                    }
            }

            switch anchor.chirality {
            case .left:
                skeletonData?.leftJoints = joints
            case .right:
                skeletonData?.rightJoints = joints
            }
        }
    }
}
