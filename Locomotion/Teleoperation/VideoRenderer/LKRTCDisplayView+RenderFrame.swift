import LiveKitWebRTC

extension LKRTCDisplayView {

    /// Receives an incoming WebRTC frame and schedules a render on the main thread.
    ///
    /// Only one render dispatch is ever in-flight at a time. If frames arrive faster
    /// than the main thread can drain them, intermediate frames are dropped and the
    /// main thread always picks up the most recent one — preventing queue buildup and
    /// the growing latency that follows.
    func renderFrame(_ frame: LKRTCVideoFrame?) {
        guard let frame,
              let pixelBuffer = extractPixelBuffer(from: frame),
              let sampleBuffer = makeSampleBuffer(from: pixelBuffer) else { return }

        renderLock.lock()
        let needsDispatch = pendingBuffer == nil
        pendingBuffer = sampleBuffer
        renderLock.unlock()

        guard needsDispatch else { return }

        DispatchQueue.main.async { [weak self] in
            self?.drainPendingBuffer()
        }
    }

    private func drainPendingBuffer() {
        renderLock.lock()
        let buffer = pendingBuffer
        pendingBuffer = nil
        renderLock.unlock()

        guard let buffer else { return }

        if sampleBufferLayer.sampleBufferRenderer.status == .failed {
            sampleBufferLayer.sampleBufferRenderer.flush()
        }
        sampleBufferLayer.sampleBufferRenderer.enqueue(buffer)
    }

    private func makeSampleBuffer(from pixelBuffer: CVPixelBuffer) -> CMSampleBuffer? {
        var timing = CMSampleTimingInfo(
            duration: CMTime(value: 1, timescale: 30),
            presentationTimeStamp: CMClockGetTime(CMClockGetHostTimeClock()),
            decodeTimeStamp: .invalid
        )

        var formatDesc: CMVideoFormatDescription?
        CMVideoFormatDescriptionCreateForImageBuffer(
            allocator: nil,
            imageBuffer: pixelBuffer,
            formatDescriptionOut: &formatDesc
        )
        guard let formatDesc else { return nil }

        var sampleBuffer: CMSampleBuffer?
        CMSampleBufferCreateForImageBuffer(
            allocator: nil,
            imageBuffer: pixelBuffer,
            dataReady: true,
            makeDataReadyCallback: nil,
            refcon: nil,
            formatDescription: formatDesc,
            sampleTiming: &timing,
            sampleBufferOut: &sampleBuffer
        )
        return sampleBuffer
    }
}
