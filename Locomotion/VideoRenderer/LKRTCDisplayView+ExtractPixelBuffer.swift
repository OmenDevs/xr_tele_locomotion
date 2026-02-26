//
//  LKRTCDisplayView+ExtractPixelBuffer.swift
//  TestWebRTC
//
//  Created by Can Dindar on 25/02/26.
//

import LiveKitWebRTC

extension LKRTCDisplayView {

    /// Extracts a `CVPixelBuffer` from an incoming WebRTC video frame.
    ///
    /// This method handles two scenarios:
    /// 1. The frame already contains a `CVPixelBuffer`.
    /// 2. The frame is in **I420** format, requiring manual conversion to an **NV12** buffer.
    ///
    /// - Parameter frame: The `LKRTCVideoFrame` received from the WebRTC track.
    /// - Returns: A `CVPixelBuffer` formatted for visionOS display, or `nil` if conversion fails.
    func extractPixelBuffer(from frame: LKRTCVideoFrame) -> CVPixelBuffer? {
        // If the frame is already a native CVPixelBuffer, return it directly
        if let cvBuffer = frame.buffer as? LKRTCCVPixelBuffer {
            return cvBuffer.pixelBuffer
        }

        // Otherwise, convert the buffer to I420 (Planar Y, U, V)
        guard let i420 = frame.buffer.toI420() as? LKRTCI420Buffer else { return nil }

        let width  = Int(frame.width)
        let height = Int(frame.height)

        var output: CVPixelBuffer?
        // Create a Bi-Planar (NV12) pixel buffer: Plane 0 is Y, Plane 1 is interleaved UV
        CVPixelBufferCreate(
            kCFAllocatorDefault,
            width, height,
            kCVPixelFormatType_420YpCbCr8BiPlanarFullRange,
            nil,
            &output
        )

        guard let out = output else { return nil }

        // Access the buffer memory
        CVPixelBufferLockBaseAddress(out, [])
        defer { CVPixelBufferUnlockBaseAddress(out, []) }

        // --- Step 1: Copy Y (Luminance) Plane ---
        if let yDst = CVPixelBufferGetBaseAddressOfPlane(out, 0) {
            let yStride = CVPixelBufferGetBytesPerRowOfPlane(out, 0)
            for row in 0..<height {
                memcpy(
                    yDst.advanced(by: row * yStride),
                    i420.dataY.advanced(by: row * Int(i420.strideY)),
                    width
                )
            }
        }

        // --- Step 2: Interleave U and V (Chrominance) into the UV Plane ---
        // This converts the planar I420 format into the bi-planar NV12 format.
        if let uvDst = CVPixelBufferGetBaseAddressOfPlane(out, 1) {
            let uvStride = CVPixelBufferGetBytesPerRowOfPlane(out, 1)
            let uvPtr = uvDst.bindMemory(to: UInt8.self, capacity: (height / 2) * uvStride)

            for row in 0..<(height / 2) {
                let uRow = i420.dataU.advanced(by: row * Int(i420.strideU))
                let vRow = i420.dataV.advanced(by: row * Int(i420.strideV))

                for col in 0..<(width / 2) {
                    // NV12 expects U and V to alternate (U, V, U, V...)
                    uvPtr[row * uvStride + col * 2]     = uRow[col]
                    uvPtr[row * uvStride + col * 2 + 1] = vRow[col]
                }
            }
        }
        return out
    }
}
