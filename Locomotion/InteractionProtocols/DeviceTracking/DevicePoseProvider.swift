import ARKit
import QuartzCore

@MainActor
final class DevicePoseProvider {

    private let arkitSession = ARKitSession()
    private let worldTrackingProvider = WorldTrackingProvider()

    func start() async {
        do {
            try await arkitSession.run([worldTrackingProvider])
        } catch {
            print("Failed to start WorldTrackingProvider: \(error)")
        }
    }

    /// Latest device pose in the same ARKit world origin as hand joints.
    /// Synchronous query — call at the moment you need it (e.g. pinch start).
    func currentDeviceTransform() -> simd_float4x4? {
        guard worldTrackingProvider.state == .running,
              let anchor = worldTrackingProvider.queryDeviceAnchor(atTimestamp: CACurrentMediaTime())
        else { return nil }
        return anchor.originFromAnchorTransform
    }
}
