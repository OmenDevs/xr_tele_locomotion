# Input Module

Translate user actions into a normalized motion command for the robot locomotion or simulator.

## Overview

The Input module produces a normalized (velocityX, velocityY,
angularVelocity) triplet in the range -1…+1 from operator input
from both interaction protocols. Downstream consumers, `RobotWebRTCClient`
for live teleoperation and `POVSimulatorViewModel` for the offline scenario,
consume this triplet without depending on the specific interaction
protocol that generated it.

### The three interaction protocols

Locomotion ships three interchangeable input protocols. The active one is
chosen at runtime by ``InteractionConfig`` and only one runs at a time.

- **Joystick3D**, A RealityKit deck floating in space. Pinching with the
  left hand drags a virtual joystick handle (linear), pinching with the
  right hand drags a lever (angular). Hand movement is expressed in the
  deck's local frame, so the deck's orientation defines "forward".
- **GestureBased**, A hands-free protocol with no visible controls. The
  first hand to pinch wins; that hand's drag becomes linear velocity in a
  yaw-locked user frame, and rotation around the thumb axis becomes
  angular velocity. A pair of perpendicular rings (``DragGestureVisualizer``)
  appears in space as feedback.

### Hand and device tracking

Joystick3D and GestureBased both consume ARKit data:

- ``HandSkeletonProvider`` runs an `ARKitSession` with a
  `HandTrackingProvider` and writes the latest joint transforms and pinch
  state into a shared ``HandSkeletonData`` snapshot. All transforms are in
  ARKit world space.
- ``DevicePoseProvider`` runs the same session pattern with a
  `WorldTrackingProvider` to expose the head pose, used by GestureBased to
  capture a yaw-only frame at pinch start.

Pinch detection is a 2 cm distance threshold between the thumb tip and the
middle-finger tip, see ``HandSkeletonProvider``.

### The shared contract

Every protocol writes into the same three fields on ``InputViewModel``:

- ``InputViewModel/velocityX`` and ``InputViewModel/velocityY``,
  normalized linear velocity, `-1…+1`.
- ``InputViewModel/angularVelocity``, normalized angular velocity, `-1…+1`.
- ``InputViewModel/isActive`` and ``InputViewModel/activeHand``,
  optional flags used by the gesture-based protocol to signal which hand
  currently owns the gesture.

This narrow contract is the seam that keeps the input layer decoupled from
teleoperation and simulation. The wire format used by ``RobotWebRTCClient``
maps directly: `velocityX → vx`, `velocityY → vy`,
`angularVelocity → omega`.

## Topics

### Shared Model

- ``InputViewModel``
- ``ActiveHand``

### Joystick3D

- ``Joystick3DView``
- ``PinchInputViewModel``

### Gesture-Based

- ``GestureInputViewModel``
- ``TurnGestureProcessor``
- ``DragGestureVisualizer``
- ``DragVisualizerState``

### Hand and Device Tracking

- ``HandSkeletonProvider``
- ``HandSkeletonData``
- ``DevicePoseProvider``
