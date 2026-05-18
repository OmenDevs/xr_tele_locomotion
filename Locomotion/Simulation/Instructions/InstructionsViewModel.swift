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
            completion: .rotateRight),
        Instruction(
            text: "While pinching, try rotating your wrist to the left",
            video: nil,
            completion: .rotateLeft)
    ]

    static let joytick3D: [Instruction] = [
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
            completion: .rotateRight),
        Instruction(
            text: "While pinching, try rotating your wrist to the left",
            video: nil,
            completion: .rotateLeft)
    ]
}
