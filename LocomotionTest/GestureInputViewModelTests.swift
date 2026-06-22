import Testing
import simd
@testable import Locomotion

@MainActor
struct GestureInputViewModelTests {

    private let tolerance: Double = 1e-5

    /// With no pinch on either hand, the view model must not touch
    /// `InputViewModel` and must keep the visualization fields nil.
    @Test func noPinchLeavesStateIdle() {
        let gesture = GestureInputViewModel()
        let state = InputViewModel()
        let skeleton = makeSkeleton()

        gesture.update(skeletonData: skeleton, headTransform: nil, state: state)

        #expect(state.velocityX == 0.0)
        #expect(state.velocityY == 0.0)
        #expect(gesture.dragOrigin == nil)
        #expect(gesture.cursorPoint == nil)
        #expect(gesture.frozenYaw == nil)
    }

    /// First pinch initializes origin and starts with zero velocity.
    @Test func acquisitionCapturesOriginAndLeavesVelocityZero() {
        let gesture = GestureInputViewModel()
        let state = InputViewModel()
        let origin = SIMD3<Float>(0, 1, -0.5)

        let skeleton = makeSkeleton(leftPinch: true,
                                    leftThumb: origin,
                                    leftMiddle: origin)

        gesture.update(skeletonData: skeleton, headTransform: nil, state: state)

        #expect(gesture.dragOrigin == origin)
        #expect(gesture.cursorPoint == origin)
        #expect(gesture.frozenYaw == 0)
        #expect(state.velocityX == 0.0)
        #expect(state.velocityY == 0.0)
    }

    /// Releasing pinch clears velocity and all gesture state.
    @Test func releaseClearsVelocityAndVisualizationState() {
        let gesture = GestureInputViewModel()
        let state = InputViewModel()
        let origin = SIMD3<Float>.zero
        let offset = SIMD3<Float>(0.08, 0, 0)

        gesture.update(skeletonData: makeSkeleton(leftPinch: true,
                                                  leftThumb: origin,
                                                  leftMiddle: origin),
                       headTransform: nil,
                       state: state)
        
        gesture.update(skeletonData: makeSkeleton(leftPinch: true,
                                                  leftThumb: origin + offset,
                                                  leftMiddle: origin + offset),
                       headTransform: nil,
                       state: state)
        #expect(state.velocityX != 0.0) // Sanity: gesture is actually driving.

        // Release.
        gesture.update(skeletonData: makeSkeleton(),
                       headTransform: nil,
                       state: state)

        #expect(state.velocityX == 0.0)
        #expect(state.velocityY == 0.0)
        #expect(gesture.dragOrigin == nil)
        #expect(gesture.cursorPoint == nil)
        #expect(gesture.frozenYaw == nil)
    }

    /// Left hand wins when both hands pinch simultaneously.
    @Test func leftHandWinsWhenBothPinchSimultaneously() {
        let gesture = GestureInputViewModel()
        let state = InputViewModel()
        let leftOrigin = SIMD3<Float>(-0.1, 1, -0.5)
        let rightOrigin = SIMD3<Float>(0.1, 1, -0.5)

        // Frame 1: both hands pinch, left should be locked.
        gesture.update(skeletonData: makeSkeleton(leftPinch: true,
                                                  leftThumb: leftOrigin,
                                                  leftMiddle: leftOrigin,
                                                  rightPinch: true,
                                                  rightThumb: rightOrigin,
                                                  rightMiddle: rightOrigin),
                       headTransform: nil,
                       state: state)

        #expect(gesture.dragOrigin == leftOrigin)

        // Frame 2: only the right hand keeps pinching. If left really
        // owned the lock, the gesture must release here.
        gesture.update(skeletonData: makeSkeleton(rightPinch: true,
                                                  rightThumb: rightOrigin,
                                                  rightMiddle: rightOrigin),
                       headTransform: nil,
                       state: state)

        #expect(gesture.dragOrigin == nil)
        #expect(state.velocityX == 0.0)
        #expect(state.velocityY == 0.0)
    }

    /// Builds a `HandSkeletonData` with the given pinch flags and
    /// thumb/middle-tip world positions. Other joints are left at
    /// identity, which is fine because the gesture-based view model
    /// only reads thumb and middle tips.
    private func makeSkeleton(leftPinch: Bool = false,
                              leftThumb: SIMD3<Float> = .zero,
                              leftMiddle: SIMD3<Float> = .zero,
                              rightPinch: Bool = false,
                              rightThumb: SIMD3<Float> = .zero,
                              rightMiddle: SIMD3<Float> = .zero) -> HandSkeletonData {
        let skeleton = HandSkeletonData()
        skeleton.isLeftPinch = leftPinch
        skeleton.leftThumbTip = transform(at: leftThumb)
        skeleton.leftMiddleTip = transform(at: leftMiddle)
        skeleton.isRightPinch = rightPinch
        skeleton.rightThumbTip = transform(at: rightThumb)
        skeleton.rightMiddleTip = transform(at: rightMiddle)
        return skeleton
    }

    /// Returns a translation-only 4x4 matrix at the given position.
    private func transform(at position: SIMD3<Float>) -> simd_float4x4 {
        var matrix = matrix_identity_float4x4
        matrix.columns.3 = SIMD4<Float>(position.x, position.y, position.z, 1)
        return matrix
    }
}
