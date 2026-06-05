import LiveKitWebRTC
import SwiftUI

/// A SwiftUI wrapper for `LKRTCDisplayView` to allow its use in SwiftUI layouts.
struct LKRTCVideoViewRepresentable: UIViewRepresentable {

    /// The remote video track to be rendered in this view.
    let videoTrack: LKRTCVideoTrack

    /// Creates the custom renderer view and attaches it to the video track.
    func makeUIView(context: Context) -> LKRTCDisplayView {
        let view = LKRTCDisplayView()
        videoTrack.add(view) // Starts sending frames to the view's renderFrame method
        return view
    }

    /// Updates the view when the SwiftUI state changes.
    func updateUIView(_ uiView: LKRTCDisplayView, context: Context) {
        // Re-adding the track ensures the view remains the active renderer
        videoTrack.add(uiView)
    }
}
