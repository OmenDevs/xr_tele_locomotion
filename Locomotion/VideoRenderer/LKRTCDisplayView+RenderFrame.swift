//
//  LKRTCDisplayView+RenderFrame.swift
//  TestWebRTC
//
//  Created by Can Dindar on 25/02/26.
//

import LiveKitWebRTC

extension LKRTCDisplayView {
    
    /// Processes and renders a video frame.
    ///
    /// This method converts the pixel buffer into a `CMSampleBuffer`, adds timing metadata,
    /// and enqueues it to the `AVSampleBufferDisplayLayer`.
    ///
    /// - Parameter frame: The video frame to render.
    func renderFrame(_ frame: LKRTCVideoFrame?) {
        guard let frame else { return }
        guard let pixelBuffer = extractPixelBuffer(from: frame) else { return }

        // Create timing info (required for the display layer to know when to show the frame)
        var timing = CMSampleTimingInfo(
            duration: CMTime(value: 1, timescale: 30),
            presentationTimeStamp: CMClockGetTime(CMClockGetHostTimeClock()),
            decodeTimeStamp: .invalid
        )
        
        // Create a video format description from the image buffer
        var formatDesc: CMVideoFormatDescription?
        CMVideoFormatDescriptionCreateForImageBuffer(
            allocator: nil,
            imageBuffer: pixelBuffer,
            formatDescriptionOut: &formatDesc
        )
        guard let formatDesc else { return }

        // Create the final Sample Buffer
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
        
        guard let sampleBuffer else { return }

        // Enqueue the frame to the layer on the main thread
        Task { @MainActor [weak self] in
            guard let self else { return }
            
            // If the renderer enters a failed state (e.g., due to backgrounding), flush it
            if self.sampleBufferLayer.sampleBufferRenderer.status == .failed {
                self.sampleBufferLayer.sampleBufferRenderer.flush()
            }
            
            self.sampleBufferLayer.sampleBufferRenderer.enqueue(sampleBuffer)
        }
    }
}
