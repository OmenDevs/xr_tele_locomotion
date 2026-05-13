# Contributing to Locomotion

A warm welcome, and thank you for thinking about contributing to Locomotion!
We want to make the process as easy and transparent as possible, whether you're reporting a bug, submitting a fix, proposing a new feature, or improving the documentation.
Reading these guidelines will make things smoother for everyone involved.

---

## 1. Getting Started

* **Fork** the repository to your GitHub account.
* **Clone** your fork:

  ```bash
  git clone git@github.com:<your-org>/Locomotion.git
  cd Locomotion
  ```
* **Install** dependencies and verify the project builds:
  * Open `Locomotion.xcodeproj` in Xcode and let Swift packages resolve.
  * For the server see the [Server README](Server/README.md) for setup details.

### Prerequisites

* Xcode with the visionOS SDK
* Python 3 (see `Server/requirements.txt`)
* A working CycloneDDS setup if you are exercising the velocity, command path
* `librealsense` if you're using a RealSense camera, see the [Server README](Server/README.md) for setup details


> **WebRTC**: the app depends on the [LiveKitWebRTC](https://github.com/livekit/webrtc-xcframework) Swift package, a fork of WebRTC that ships visionOS binaries (stock WebRTC does not).


## 2. Commit Guidelines

We follow the [Conventional Commits](https://www.conventionalcommits.org/) specification to keep our git history consistent and readable.

### Format

```
<type>(<scope>): <subject>

```

### Types

| Type       | Description                                                   |
| ---------- | ------------------------------------------------------------- |
| `feat`     | New feature for the user                                      |
| `fix`      | Bug fix                                                       |
| `docs`     | Documentation                                                 |
| `style`    | Formatting / whitespace, no logic changes                     |
| `refactor` | Code changes that neither fix bugs nor add features           |
| `perf`     | Performance improvements                                      |
| `test`     | Adding or updating tests                                      |
| `chore`    | Maintenance (dependencies, tooling, configuration)            |

---

## 3. Code Conventions

* **Swift**: match the surrounding style. Keep view models testable and free of UI imports where possible.
* **SwiftLint**: we enforce style with SwiftLint, integrated via the [SwiftLintPlugins](https://github.com/SimplyDanny/SwiftLintPlugins) Swift package — no local `brew install` needed. Lint runs automatically as part of the Xcode build; resolve any warnings or errors before pushing.
* **Wire protocol**: the server expects JSON keys `vx`, `vy`, `omega`. Do **not** rename these on the wire even if Swift-side names differ.
* Avoid comments that restate what the code does. Comment only non-obvious "why".

---

## 4. Pre-Submission Checklist

Before opening a Pull Request:

* [ ] Add or update **unit tests** under `LocomotionAppTests/` for any new or modified functionality.
* [ ] Ensure all tests **pass** locally.
* [ ] Verify the app builds cleanly on the visionOS simulator or device.
* [ ] Build the app and resolve any SwiftLint warnings or errors surfaced by the [SwiftLintPlugins](https://github.com/SimplyDanny/SwiftLintPlugins) build plugin.
* [ ] If you touched the server or the client, exercise the affected path (`python app.py`) and confirm connection still works.

---

## 5. Merging & Branches

After approvals and a green CI pipeline:

* The PR author may **merge** into `Development`.
* Delete your branch after merging to keep the repo clean.

* `Development` is the active integration branch. Open all PRs against this.
* `main` is the release branch. Only updated when a new version ships by the maintainers.

---

## 6. Bug Reports

Search existing issues first, then open a GitHub issue with:

* **Summary** and steps to reproduce (minimal repro preferred).
* **Expected vs. actual** behavior, with error messages verbatim.
* **Environment**: visionOS / device, Xcode version, server commit, Python version.
* **Logs / screenshots** — redact anything sensitive.

Title format: `[area] short description` (e.g., `[teleop] joystick drift when idle`).

For security issues, contact the maintainers directly instead of filing a public issue.

---

## 7. License & Support

By contributing, you agree that your contributions are licensed under the terms in [LICENSE](LICENSE). 
For questions or issues, feel free to open an **issue** on GitHub.

Thank you for helping make Locomotion better! 🚀
