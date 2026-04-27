import RealityKit
import UIKit
import simd

struct DragVisualizerState {
    let origin: SIMD3<Float>
    let cursor: SIMD3<Float>
}

/// Manages RealityKit entities that visualize the drag gesture:
/// a horizontal outline ring at the saturation radius, a center dot at
/// the pinch origin, and a moving cursor dot tracking the clamped drag.
@MainActor
final class DragGestureVisualizer {

    // MARK: - Public

    let rootEntity = Entity()

    // MARK: - Configuration

    private let radius: Float = 0.16          // matches GestureInputViewModel.dragScale
    private let ringThickness: Float = 0.003
    private let centerDotRadius: Float = 0.005
    private let cursorDotRadius: Float = 0.008
    private let ringSegments: Int = 64

    // MARK: - Child Entities

    private var centerDotEntity: ModelEntity?
    private var ringEntity: ModelEntity?
    private var cursorDotEntity: ModelEntity?
    private var isShowing = false

    // MARK: - Initialization

    init() {
        rootEntity.name = "DragGestureVisualizer"
        rootEntity.isEnabled = false
    }

    // MARK: - Public API

    func update(with state: DragVisualizerState) {
        if !isShowing {
            buildEntities()
            rootEntity.isEnabled = true
            isShowing = true
        }

        // Root sits at the pinch origin, axis-aligned with world.
        // The ring lies in the world XZ plane, matching the drag input axes.
        rootEntity.position = state.origin
        rootEntity.orientation = simd_quatf()

        centerDotEntity?.position = .zero
        ringEntity?.position = .zero

        // Cursor offset is purely horizontal; flatten any y drift to the disk plane.
        let local = state.cursor - state.origin
        cursorDotEntity?.position = SIMD3<Float>(local.x, 0, local.z)
    }

    func hide() {
        rootEntity.isEnabled = false
        isShowing = false
    }

    // MARK: - Build Entities

    private func buildEntities() {
        guard centerDotEntity == nil else { return }

        // --- Center dot (white) at pinch origin ---
        let centerMesh = MeshResource.generateSphere(radius: centerDotRadius)
        var centerMat = UnlitMaterial()
        centerMat.color = .init(tint: .white)
        let center = ModelEntity(mesh: centerMesh, materials: [centerMat])
        center.name = "dragCenter"
        rootEntity.addChild(center)
        centerDotEntity = center

        // --- Outline ring (white) at saturation radius ---
        if let ringMesh = buildRingMesh(
            radius: radius, thickness: ringThickness, segments: ringSegments
        ) {
            var ringMat = UnlitMaterial()
            ringMat.color = .init(tint: .white)
            ringMat.faceCulling = .none
            let ring = ModelEntity(mesh: ringMesh, materials: [ringMat])
            ring.name = "dragRing"
            rootEntity.addChild(ring)
            ringEntity = ring
        }

        // --- Cursor dot (cyan) inside the ring ---
        let cursorMesh = MeshResource.generateSphere(radius: cursorDotRadius)
        var cursorMat = UnlitMaterial()
        cursorMat.color = .init(tint: .cyan)
        let cursor = ModelEntity(mesh: cursorMesh, materials: [cursorMat])
        cursor.name = "dragCursor"
        rootEntity.addChild(cursor)
        cursorDotEntity = cursor
    }

    // MARK: - Mesh Generation

    /// Flat annulus in the local XZ plane, centered at origin.
    /// Built from two concentric vertex rings stitched with quads.
    private func buildRingMesh(radius: Float, thickness: Float, segments: Int) -> MeshResource? {
        guard segments >= 3 else { return nil }

        let inner = max(radius - thickness / 2, 0.0001)
        let outer = radius + thickness / 2

        var positions: [SIMD3<Float>] = []
        var normals: [SIMD3<Float>] = []
        var indices: [UInt32] = []

        let step = (2.0 * .pi) / Float(segments)
        for idx in 0..<segments {
            let theta = step * Float(idx)
            let cosT = cos(theta)
            let sinT = sin(theta)
            positions.append(SIMD3<Float>(inner * cosT, 0, inner * sinT))
            positions.append(SIMD3<Float>(outer * cosT, 0, outer * sinT))
            normals.append(SIMD3<Float>(0, 1, 0))
            normals.append(SIMD3<Float>(0, 1, 0))
        }

        for idx in 0..<segments {
            let next = (idx + 1) % segments
            let index0 = UInt32(idx * 2)        // inner current
            let index1 = UInt32(idx * 2 + 1)    // outer current
            let index2 = UInt32(next * 2)       // inner next
            let index3 = UInt32(next * 2 + 1)   // outer next

            indices.append(contentsOf: [index0, index1, index3])
            indices.append(contentsOf: [index0, index3, index2])
        }

        var descriptor = MeshDescriptor(name: "dragRing")
        descriptor.positions = MeshBuffers.Positions(positions)
        descriptor.normals = MeshBuffers.Normals(normals)
        descriptor.primitives = .triangles(indices)

        return try? MeshResource.generate(from: [descriptor])
    }
}
