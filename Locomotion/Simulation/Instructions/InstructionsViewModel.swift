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
            video: "Pinch_Gesture2",
            completion: .pinch),
        Instruction(
            text: "Now try to move the robot by dragging the ball from the starting point forward",
            video: "Astrolabium_Forward",
            completion: .moveForward),
        Instruction(
            text: "Now drag it to the back to move the robot backward",
            video: "Astrolabium_Backward",
            completion: .moveBackward),
        Instruction(
            text: "To move sideways, drag the ball from the starting point left or right",
            video: "Astrolabium_Left_and_Right",
            completion: .moveSideways),
        Instruction(
            text: "Rotating your wrist makes the robot rotate. While pinching, try rotating your wrist to the right",
            video: "Astrolabium_Right",
            completion: .rotateLeft),
        Instruction(
            text: "Now rotate your wrist to the left",
            video: "Astrolabium_Left",
            completion: .rotateRight),
        Instruction(
            text: "Good Job! You have completed all the instructions.",
            video: nil,
            completion: .rotateLeft)
    ]

    static let joytick3D: [Instruction] = [
        Instruction(
            text: "To control the robot use your left hand and pinch your middle finger and thumb.",
            video: "Pinch_Gesture",
            completion: .pinch),
        Instruction(
            text: "With the left joystick you can move the robot in any direction. Try to move forward.",
            video: "Joystick_Forward",
            completion: .moveForward),
        Instruction(
            text: "Now pull your hand back to move backward",
            video: "Joystick_Backward",
            completion: .moveBackward),
        Instruction(
            text: "Lastly, move your left hand sideways to go left or right",
            video: "Joystick_Left_And_Right",
            completion: .moveSideways),
        Instruction(
            text: """
            The lever you see on the right is to control the direction the robot faces.
            Pinch with your right hand and move it to the left
            """,
            video: "Lever_Left",
            completion: .rotateRight),
        Instruction(
            text: "Now move it to the right",
            video: "Lever_Right",
            completion: .rotateLeft),
        Instruction(
            text: "Good Job! You have completed all the instructions.",
            video: nil,
            completion: .rotateLeft)
    ]
}
