# AI Agent Instructions (agents.md)

This document provides context and guidelines for AI agents assisting with the DaVinci Console Binding project.

## Project Architecture

*   **Core Engine:** The primary logic is an embedded C# class (`DaVinciAssemblyEngine`) within a PowerShell script (`DaVinciGamepad.ps1`). This class utilizes P/Invoke to interface directly with Windows APIs (`xinput1_4.dll` for gamepad input, `user32.dll` for keyboard/mouse output and window management).
*   **Data-Driven Configuration:** Version 2 (V2) uses a `bindings.json` file. The PowerShell script parses this JSON and injects the mappings and settings into the C# engine at runtime.
*   **Layered Input:** The input system evaluates modifier buttons (Back, LB, RB) before executing the primary button action, enabling complex chorded inputs.

## Troubleshooting Guidelines for Agents

*   **Controller Not Detected:** Verify the user is using an XInput compatible device. The C# engine specifically calls `XInputGetState(0)`.
*   **Unrecognized Key Binding:** If a user adds a key to `bindings.json` and it fails, check the `KeyMap`, `ModifierMap`, and `ExtendedKeys` dictionaries in the C# source (`DaVinciGamepad.ps1`). New custom keys must be mapped to their virtual key codes (VK_*) there.
*   **Inputs Not Reaching DaVinci:** The script checks `GetForegroundWindow()` and only sends inputs if the active window process name contains "Resolve". Ensure the user actually has Resolve focused.

## Future Enhancement Opportunities

When suggesting improvements or writing new features, consider the following areas:

1.  **GUI Configurator:** A lightweight UI (e.g., using Windows Forms or WPF in PowerShell) to visually edit `bindings.json`.
2.  **Macro Support:** Expanding the JSON schema to allow an array of actions with optional delays for a single button press.
3.  **DirectInput / MIDI Support:** Abstracting the input layer to support devices beyond XInput, such as MIDI controllers or generic DirectInput gamepads.
4.  **Profile Switching:** Adding the ability to load different `.json` profiles on the fly via a specific button combo.

## Coding Standards

*   Maintain the single-file deployability of the core script (avoid adding external DLL dependencies if possible).
*   Keep the C# code performant; this loop runs every few milliseconds. Avoid garbage collection spikes in the main loop.
*   Do not use emojis or emdashes in documentation or logs.
