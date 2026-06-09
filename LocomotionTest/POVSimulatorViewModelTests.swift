import Testing
@testable import Locomotion

struct POVSimulatorViewModelTests {

    private let tolerance: Double = 1e-9

    /// All-zero input must leave `scenarioX`, `scenarioY`, and
    /// `scenarioHeading` exactly as they were. Guards the early-return
    /// branch in `update(deltaTime:)`.
    @Test func zeroInputLeavesPoseUnchanged() {
        let sim = POVSimulatorViewModel()
        sim.scenarioX = 1.0
        sim.scenarioY = 2.0
        sim.scenarioHeading = 0.3

        sim.updateScenario(normalizedVelocityX: 0,
                           normalizedVelocityY: 0,
                           normalizedAngularVelocity: 0,
                           deltaTime: 1.0)

        #expect(sim.scenarioX == 1.0)
        #expect(sim.scenarioY == 2.0)
        #expect(sim.scenarioHeading == 0.3)
    }

    /// With `isSimulatorActive == false`, even saturated input must not
    /// move the pose. Covers `setSimulatorActive(_:)` and the active flag.
    @Test func inactiveSimulatorIgnoresInput() {
        let sim = POVSimulatorViewModel()
        sim.setSimulatorActive(false)

        sim.updateScenario(normalizedVelocityX: 1,
                           normalizedVelocityY: 1,
                           normalizedAngularVelocity: 1,
                           deltaTime: 1.0)

        #expect(sim.scenarioX == 0.0)
        #expect(sim.scenarioY == 0.0)
        #expect(sim.scenarioHeading == 0.0)
    }

    /// Checks that forward input at heading 0 moves only along the Y axis.
    @Test func forwardAtZeroHeadingMovesAlongY() {
        let sim = POVSimulatorViewModel()

        sim.updateScenario(normalizedVelocityX: 0,
                           normalizedVelocityY: 1,
                           normalizedAngularVelocity: 0,
                           deltaTime: 1.0)

        // Forward input should increase only Y position.
        #expect(abs(sim.scenarioX) < tolerance)
        #expect(abs(sim.scenarioY - sim.maxLinearSpeed) < tolerance)
        #expect(sim.scenarioHeading == 0.0)
    }

    /// Checks that forward movement at +π/2 heading moves along the X axis.
    @Test func forwardAtNinetyDegreesMovesAlongNegativeX() {
        let sim = POVSimulatorViewModel()
        sim.scenarioHeading = .pi / 2

        sim.updateScenario(normalizedVelocityX: 0,
                           normalizedVelocityY: 1,
                           normalizedAngularVelocity: 0,
                           deltaTime: 1.0)

        // Forward input becomes negative X movement at +π/2 heading.
        #expect(abs(sim.scenarioX - (-sim.maxLinearSpeed)) < tolerance)
        #expect(abs(sim.scenarioY) < tolerance)
    }

    /// Checks that angular input changes heading without changing position.
    @Test func angularInputAdvancesHeading() {
        let sim = POVSimulatorViewModel()

        sim.updateScenario(normalizedVelocityX: 0,
                           normalizedVelocityY: 0,
                           normalizedAngularVelocity: 1,
                           deltaTime: 0.5)

        // Heading should increase by angular speed × delta time.
        #expect(abs(sim.scenarioHeading - 0.25) < tolerance)

        // No movement input, so position stays the same.
        #expect(sim.scenarioX == 0.0)
        #expect(sim.scenarioY == 0.0)
    }
    
    /// Zero delta time should prevent any movement.
    @Test func zeroDeltaTimeIsNoOp() {
        let sim = POVSimulatorViewModel()

        sim.updateScenario(normalizedVelocityX: 1,
                           normalizedVelocityY: 1,
                           normalizedAngularVelocity: 1,
                           deltaTime: 0)

        #expect(sim.scenarioX == 0.0)
        #expect(sim.scenarioY == 0.0)
        #expect(sim.scenarioHeading == 0.0)
    }
}
