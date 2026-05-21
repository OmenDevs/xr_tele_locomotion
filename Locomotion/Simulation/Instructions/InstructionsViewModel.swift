//
//  Instructions+ViewModel.swift
//  Locomotion
//
//  Created by Julio Enrique Sanchez Guajardo on 14/05/26.
//

import Foundation

struct Instructions {
    static let astrolabium: [Instruction] = [
        Instruction(
            text: "To control the robot pinch your thumb and middle finger.",
            video: nil,
            completion: .pinch),
        Instruction(
            text: "Now try to move the robot by dragging the ball from the starting point forward",
            video: nil,
            completion: .moveForward),
        Instruction(
            text: "Now drag it to the back to move the robot backward",
            video: nil,
            completion: .moveBackward),
        Instruction(
            text: "To move sideways, drag the ball from the starting point left or right",
            video: nil,
            completion: .moveSideways),
        Instruction(
            text: "Rotating your wrist makes the robot rotate. While pinching, try rotating your wrist to the right",
            video: nil,
            completion: .rotateLeft),
        Instruction(
            text: "Now rotate your wrist to the left",
            video: nil,
            completion: .rotateRight),
        Instruction(
            text: "Good Job! You have completed all the instructions.",
            video: nil,
            completion: .rotateLeft)
    ]

    static let joytick3D: [Instruction] = [
        Instruction(
            text: "To control the robot use your left hand and pinch your middle finger and thumb.",
            video: nil,
            completion: .pinch),
        Instruction(
            text: "With the left joystick you can move the robot in any direction. Try to move forward.",
            video: nil,
            completion: .moveForward),
        Instruction(
            text: "Now pull your hand back to move backward",
            video: nil,
            completion: .moveBackward),
        Instruction(
            text: "Lastly, move your left hand sideways to go left or right",
            video: nil,
            completion: .moveSideways),
        Instruction(
            text: """
            The lever you see on the right is to control the direction the robot faces.
            Pinch with your right hand and move it to the left
            """,
            video: nil,
            completion: .rotateRight),
        Instruction(
            text: "Now move it to the right",
            video: nil,
            completion: .rotateLeft),
        Instruction(
            text: "Good Job! You have completed all the instructions.",
            video: nil,
            completion: .rotateLeft)
    ]
}
