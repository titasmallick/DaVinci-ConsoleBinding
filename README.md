# DaVinci Console Binding

A lightweight, highly customizable utility that transforms any XInput-compatible gamepad (such as an Xbox controller) into a high-performance editing console for DaVinci Resolve. By mapping gamepad inputs to DaVinci Resolve keyboard shortcuts and mouse movements, it significantly speeds up your video editing workflow.

## Features

*   **Config-Driven Customization (V2):** Easily modify button mappings and analog stick sensitivity in `bindings.json` without any programming knowledge.
*   **Multi-Layer Control System:** Utilize modifier buttons (Back, LB, RB) to access dozens of shortcuts from a standard gamepad.
*   **Pro Analog Jog Wheel:** The left analog stick functions as a variable-speed jog wheel for precise timeline navigation.
*   **Smooth Mouse Emulation:** The right analog stick controls the mouse cursor, allowing you to stay on the controller for UI interactions.
*   **Analog Timeline Zoom:** The left and right triggers smoothly zoom the timeline in and out.
*   **Low Latency Execution:** Uses direct XInput API calls via embedded C# within PowerShell for instantaneous response.
*   **Context-Aware:** Automatically pauses background processing when DaVinci Resolve is not the active window.

## Installation & Usage

1.  Download or clone this repository.
2.  Navigate to the `V2` directory.
3.  Double-click `Start-DaVinci-Gamepad.bat`.
4.  Launch DaVinci Resolve and bring it into focus.
5.  Start editing with your gamepad.

## Customizing Bindings

To change button configurations, open `V2/bindings.json` in any text editor. 
You can modify the `"keys"` value for any button combination. For example, changing `"keys": "Ctrl B"` to another valid keyboard shortcut. 

If a required key is not recognized, it may need to be added to the `KeyMap` dictionary inside the `DaVinciGamepad.ps1` source code.

## License

This project is licensed under the MIT License. See the LICENSE file for details.

## Attribution

Developed to enhance the DaVinci Resolve editing experience for creators who prefer tactile, console-style controls.
