import LiveKitWebRTC
import AVFoundation

/// A custom UIView that renders WebRTC video frames using `AVSampleBufferDisplayLayer`.
///
/// This view implements the `LKRTCVideoRenderer` protocol to receive raw video frames
/// and display them using hardware-accelerated sample buffer rendering.
class LKRTCDisplayView: UIView, LKRTCVideoRenderer {

    /// The underlying layer responsible for displaying compressed or uncompressed video frames.
    let sampleBufferLayer = AVSampleBufferDisplayLayer()

    // Guards pendingBuffer across the WebRTC render thread and main thread.
    let renderLock = NSLock()
    // Holds the latest unconsumed frame. nil means no dispatch is in flight.
    var pendingBuffer: CMSampleBuffer?

    /// Initializes the view with a black background and configures the video gravity.
    override init(frame: CGRect) {
        super.init(frame: frame)

        // Ensure the video scales correctly within the view bounds
        sampleBufferLayer.videoGravity = .resizeAspect
        sampleBufferLayer.backgroundColor = UIColor.black.cgColor

        // Add the specialized video layer as a sublayer
        layer.addSublayer(sampleBufferLayer)
    }

    /// Required initializer for storyboard/nib support (not implemented).
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    /// Keeps the `sampleBufferLayer` frame in sync with the view bounds during layout changes.
    override func layoutSubviews() {
        super.layoutSubviews()
        sampleBufferLayer.frame = bounds
    }

    /// Update the internal size state if needed (required by LKRTCVideoRenderer).
    func setSize(_ size: CGSize) {}
}
