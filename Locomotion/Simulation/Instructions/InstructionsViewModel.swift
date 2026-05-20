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
            text: "Try pinching with your middle finger and thumb to access the controls",
            video: nil,
            completion: .pinch),
        Instruction(
            text: "Try to move the robot, drag the ball from the starting point forward",
            video: nil,
            completion: .moveForward),
        Instruction(
            text: "Try to move the robot, drag the ball from the starting point backward",
            video: nil,
            completion: .moveBackward),
        Instruction(
            text: "Try to move the robot, drag the ball from the starting point left or right",
            video: nil,
            completion: .moveSideways),
        Instruction(
            text: "Rotating your wrist makes the robot rotate. While pinching, try rotating your wrist to the right",
            video: nil,
            completion: .rotateLeft),
        Instruction(
            text: "While pinching, try rotating your wrist to the right",
            video: nil,
            completion: .rotateRight),
        Instruction(
            text: "You have completed all the instructions!",
            video: nil,
            completion: .rotateLeft)
    ]

    static let joytick3D: [Instruction] = [
        Instruction(
            text: "Pinch your middle finger and thumb with your left hand to take control of the joystick",
            video: nil,
            completion: .pinch),
        Instruction(
            text: "Keep pinching with your left hand and move it forward",
            video: "Joystick_Forward",
            completion: .moveForward),
        Instruction(
            text: "Now pull your left hand back to move backward",
            video: "Joystick_Backward",
            completion: .moveBackward),
        Instruction(
            text: "Move your left hand sideways to go left or right",
            video: "Joystick_Left_And_Right",
            completion: .moveSideways),
        Instruction(
            text: "Pinch with your right hand and move it to the left",
            video: "Lever_Left",
            completion: .rotateRight),
        Instruction(
            text: "Pinch with your right hand and move it to the right",
            video: "Lever_Right",
            completion: .rotateLeft),
        Instruction(
            text: "You have completed all the instructions!",
            video: nil,
            completion: .rotateLeft)
    ]
}
