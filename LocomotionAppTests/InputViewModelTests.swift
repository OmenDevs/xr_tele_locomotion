//
//  InputViewModelTests.swift
//  LocomotionAppTests
//
//  Created by Can Dindar on 11/05/2026.
//

import Testing
@testable import LocomotionApp

@MainActor
struct InputViewModelTests {

    /// Starts with no input and zero velocities.
    @Test func freshInstanceHasNeutralDefaults() {
        let input = InputViewModel()

        #expect(input.isActive == false)
        #expect(input.activeHand == .none)
        #expect(input.velocityX == 0.0)
        #expect(input.velocityY == 0.0)
        #expect(input.angularVelocity == 0.0)
    }

    /// Reset clears all state back to neutral.
    @Test func resetFromEngagedStateReturnsToNeutral() {
        let input = InputViewModel()
        input.isActive = true
        input.activeHand = .right
        input.velocityX = 1.0
        input.velocityY = 1.0
        input.angularVelocity = 1.0

        input.reset()

        #expect(input.isActive == false)
        #expect(input.activeHand == .none)
        #expect(input.velocityX == 0.0)
        #expect(input.velocityY == 0.0)
        #expect(input.angularVelocity == 0.0)
    }

    /// Reset does nothing harmful even when already neutral.
    @Test func resetOnNeutralStateIsNoOp() {
        let input = InputViewModel()

        input.reset()

        #expect(input.isActive == false)
        #expect(input.activeHand == .none)
        #expect(input.velocityX == 0.0)
        #expect(input.velocityY == 0.0)
        #expect(input.angularVelocity == 0.0)
    }

    /// Each velocity field updates independently.
    @Test func writingOneVelocityDoesNotDisturbOthers() {
        let input = InputViewModel()

        input.velocityX = 0.5
        #expect(input.velocityX == 0.5)
        #expect(input.velocityY == 0.0)
        #expect(input.angularVelocity == 0.0)

        input.angularVelocity = -0.3
        #expect(input.velocityX == 0.5)
        #expect(input.velocityY == 0.0)
        #expect(input.angularVelocity == -0.3)
    }
}
