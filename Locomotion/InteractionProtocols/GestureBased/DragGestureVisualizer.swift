import RealityKit
import UIKit
import simd

struct DragVisualizerState {
    let origin: SIMD3<Float>
    let cursor: SIMD3<Float>
    let normalizedTurnAngle: Double
}

/// Manages RealityKit entities that visualize the drag + turn gesture:
/// - A horizontal drag ring at the saturation radius (XZ plane).
/// - A center mark at the pinch origin where the two rings cross.
/// - A cursor dot tracking the clamped drag position on the drag ring.
/// - A vertical turn ring (XY plane, faces the user) concentric with the drag ring.
/// - A ball traveling along the turn ring whose angular position reflects turn magnitude.
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

    private let turnBallRadius: Float = 0.01
    private let turnNeutralTheta: Float = .pi / 2   // top of the XY ring (+Y)
    private let turnMaxAngularTravel: Float = .pi / 2  // 90° per side at saturation

    // MARK: - Child Entities

    private var centerDotEntity: ModelEntity?
    private var dragRingEntity: ModelEntity?
    private var cursorDotEntity: ModelEntity?
    private var turnRingEntity: ModelEntity?
    private var turnBallEntity: ModelEntity?
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
        // Drag ring lies in world XZ; turn ring lies in world XY (faces -Z, the user).
        rootEntity.position = state.origin
        rootEntity.orientation = simd_quatf()

        centerDotEntity?.position = .zero
        dragRingEntity?.position = .zero
        turnRingEntity?.position = .zero

        // Cursor offset is purely horizontal; flatten any y drift to the disk plane.
        let local = state.cursor - state.origin
        cursorDotEntity?.position = SIMD3<Float>(local.x, 0, local.z)

        updateTurnBall(normalizedTurnAngle: state.normalizedTurnAngle)
    }

    func hide() {
        rootEntity.isEnabled = false
        isShowing = false
    }

    // MARK: - Build Entities

    private func buildEntities() {
        guard centerDotEntity == nil else { return }

        // --- Center mark (white) at pinch origin, where the two rings cross ---
        let centerMesh = MeshResource.generateSphere(radius: centerDotRadius)
        var centerMat = UnlitMaterial()
        centerMat.color = .init(tint: .white)
        let center = ModelEntity(mesh: centerMesh, materials: [centerMat])
        center.name = "centerMark"
        rootEntity.addChild(center)
        centerDotEntity = center

        // --- Drag ring (white) on the XZ plane ---
        if let mesh = buildRingMesh(
            radius: radius, thickness: ringThickness, segments: ringSegments,
            basisU: SIMD3<Float>(1, 0, 0),
            basisV: SIMD3<Float>(0, 0, 1),
            normal: SIMD3<Float>(0, 1, 0)
        ) {
            var mat = UnlitMaterial()
            mat.color = .init(tint: .white)
            mat.faceCulling = .none
            let ring = ModelEntity(mesh: mesh, materials: [mat])
            ring.name = "dragRing"
            rootEntity.addChild(ring)
            dragRingEntity = ring
        }

        // --- Cursor dot (cyan) on the drag ring plane ---
        let cursorMesh = MeshResource.generateSphere(radius: cursorDotRadius)
        var cursorMat = UnlitMaterial()
        cursorMat.color = .init(tint: .cyan)
        let cursor = ModelEntity(mesh: cursorMesh, materials: [cursorMat])
        cursor.name = "dragCursor"
        rootEntity.addChild(cursor)
        cursorDotEntity = cursor

        // --- Turn ring (white) on the XY plane, perpendicular to the drag ring ---
        if let mesh = buildRingMesh(
            radius: radius, thickness: ringThickness, segments: ringSegments,
            basisU: SIMD3<Float>(1, 0, 0),
            basisV: SIMD3<Float>(0, 1, 0),
            normal: SIMD3<Float>(0, 0, -1)
        ) {
            var mat = UnlitMaterial()
            mat.color = .init(tint: .white)
            mat.faceCulling = .none
            let ring = ModelEntity(mesh: mesh, materials: [mat])
            ring.name = "turnRing"
            rootEntity.addChild(ring)
            turnRingEntity = ring
        }

        // --- Turn ball (cyan) traveling along the turn ring ---
        let ballMesh = MeshResource.generateSphere(radius: turnBallRadius)
        var ballMat = UnlitMaterial()
        ballMat.color = .init(tint: .cyan)
        let ball = ModelEntity(mesh: ballMesh, materials: [ballMat])
        ball.name = "turnBall"
        rootEntity.addChild(ball)
        turnBallEntity = ball
    }

    // MARK: - Turn Ball

    /// Positions the ball on the XY-plane turn ring. Neutral is top (+Y).
    /// Positive turn → ball travels CW (from the user's view) toward +X.
    /// Negative turn → ball travels CCW toward −X. Saturation = ±90° (sides).
    private func updateTurnBall(normalizedTurnAngle: Double) {
        let signed = max(-1, min(1, Float(normalizedTurnAngle)))
        let ballTheta = turnNeutralTheta - turnMaxAngularTravel * signed
        let pos = SIMD3<Float>(radius * cos(ballTheta), radius * sin(ballTheta), 0)
        turnBallEntity?.position = pos
    }

    // MARK: - Mesh Generation

    /// Flat annulus around the local origin in the plane spanned by `basisU` × `basisV`.
    /// `basisU` and `basisV` should be orthonormal; `normal` is used for the vertex normals.
    private func buildRingMesh(
        radius: Float, thickness: Float, segments: Int,
        basisU: SIMD3<Float>, basisV: SIMD3<Float>, normal: SIMD3<Float>
    ) -> MeshResource? {
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
            positions.append(inner * cosT * basisU + inner * sinT * basisV)
            positions.append(outer * cosT * basisU + outer * sinT * basisV)
            normals.append(normal)
            normals.append(normal)
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

        var descriptor = MeshDescriptor(name: "ring")
        descriptor.positions = MeshBuffers.Positions(positions)
        descriptor.normals = MeshBuffers.Normals(normals)
        descriptor.primitives = .triangles(indices)

        return try? MeshResource.generate(from: [descriptor])
    }
}
