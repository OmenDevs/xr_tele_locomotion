import SwiftUI
import RealityKit

struct PinchTestView: View {

    @State private var handSkeletonProvider = HandSkeletonProvider()
    @State private var skeletonData = HandSkeletonData()
    @State private var pinchInput = PinchInputViewModel.shared
    @State private var frameSubscription: EventSubscription?

    var body: some View {
        RealityView { content in
            handSkeletonProvider.skeletonData = skeletonData
            pinchInput.skeletonData = skeletonData

            Task { await handSkeletonProvider.start() }

            frameSubscription = content.subscribe(to: SceneEvents.Update.self) { _ in
                pinchInput.update()
            }
        }
    }
}
