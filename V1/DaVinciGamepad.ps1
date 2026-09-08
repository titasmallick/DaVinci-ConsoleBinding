<#
================================================================================
DaVinci Resolve Gamepad Hub - 100% Assembly Pro Edition
Enables 100% of editing assembly from the gamepad:
- Source & Timeline toggle, In/Out marking, Append, Insert, Overwrite, Replace
- Analog Jog Wheel, Single-frame step, Jump cut points, Shuttle J/K/L
- Blade at Playhead, Blade All Tracks, Ripple Delete, Lift/Delete
- Nudge 1-frame and 5-frame, Slip/Slide, Ripple Start/End
- Transitions (Video & Audio Crossfade), Clip Enable/Disable, Snapping, Linked Select
- Smooth Mouse Control, Left Click, Right Click
- Page Switching (Cut, Edit, Color, Deliver), Quick Save, Fullscreen Cinema, Undo/Redo
================================================================================
#>

$source = @"
using System;
using System.Diagnostics;
using System.Runtime.InteropServices;
using System.Threading;

public class DaVinciAssemblyEngine {
    [DllImport("xinput1_4.dll")]
    public static extern int XInputGetState(int dwUserIndex, ref XINPUT_STATE pState);

    [DllImport("user32.dll")]
    public static extern IntPtr GetForegroundWindow();

    [DllImport("user32.dll")]
    public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint processId);

    [DllImport("user32.dll", SetLastError = true)]
    public static extern uint SendInput(uint nInputs, INPUT[] pInputs, int cbSize);

    [DllImport("user32.dll")]
    public static extern void mouse_event(uint dwFlags, int dx, int dy, uint dwData, UIntPtr dwExtraInfo);

    public const uint MOUSEEVENTF_MOVE = 0x0001;
    public const uint MOUSEEVENTF_LEFTDOWN = 0x0002;
    public const uint MOUSEEVENTF_LEFTUP = 0x0004;
    public const uint MOUSEEVENTF_RIGHTDOWN = 0x0008;
    public const uint MOUSEEVENTF_RIGHTUP = 0x0010;

    [StructLayout(LayoutKind.Sequential)]
    public struct XINPUT_STATE {
        public uint dwPacketNumber;
        public XINPUT_GAMEPAD Gamepad;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct XINPUT_GAMEPAD {
        public ushort wButtons;
        public byte bLeftTrigger;
        public byte bRightTrigger;
        public short sThumbLX;
        public short sThumbLY;
        public short sThumbRX;
        public short sThumbRY;
    }

    public const ushort DPAD_UP = 0x0001;
    public const ushort DPAD_DOWN = 0x0002;
    public const ushort DPAD_LEFT = 0x0004;
    public const ushort DPAD_RIGHT = 0x0008;
    public const ushort BTN_START = 0x0010;
    public const ushort BTN_BACK = 0x0020;
    public const ushort THUMB_LEFT = 0x0040;
    public const ushort THUMB_RIGHT = 0x0080;
    public const ushort SHOULDER_LEFT = 0x0100;
    public const ushort SHOULDER_RIGHT = 0x0200;
    public const ushort BTN_A = 0x1000;
    public const ushort BTN_B = 0x2000;
    public const ushort BTN_X = 0x4000;
    public const ushort BTN_Y = 0x8000;

    [StructLayout(LayoutKind.Sequential)]
    public struct INPUT {
        public uint type;
        public KEYBDINPUT ki;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct KEYBDINPUT {
        public ushort wVk;
        public ushort wScan;
        public uint dwFlags;
        public uint time;
        public UIntPtr dwExtraInfo;
        public uint unused1;
        public uint unused2;
    }

    public const uint INPUT_KEYBOARD = 1;
    public const uint KEYEVENTF_EXTENDEDKEY = 0x0001;
    public const uint KEYEVENTF_KEYUP = 0x0002;

    public const ushort VK_BACK = 0x08;
    public const ushort VK_TAB = 0x09;
    public const ushort VK_RETURN = 0x0D;
    public const ushort VK_SHIFT = 0x10;
    public const ushort VK_CONTROL = 0x11;
    public const ushort VK_MENU = 0x12; // Alt
    public const ushort VK_SPACE = 0x20;
    public const ushort VK_HOME = 0x24;
    public const ushort VK_LEFT = 0x25;
    public const ushort VK_UP = 0x26;
    public const ushort VK_RIGHT = 0x27;
    public const ushort VK_DOWN = 0x28;
    public const ushort VK_END = 0x23;
    public const ushort VK_DELETE = 0x2E;

    public const ushort VK_KEY_3 = 0x33;
    public const ushort VK_KEY_4 = 0x34;
    public const ushort VK_KEY_6 = 0x36;
    public const ushort VK_KEY_8 = 0x38;

    public const ushort VK_KEY_A = 0x41;
    public const ushort VK_KEY_B = 0x42;
    public const ushort VK_KEY_D = 0x44;
    public const ushort VK_KEY_F = 0x46;
    public const ushort VK_KEY_I = 0x49;
    public const ushort VK_KEY_J = 0x4A;
    public const ushort VK_KEY_K = 0x4B;
    public const ushort VK_KEY_L = 0x4C;
    public const ushort VK_KEY_M = 0x4D;
    public const ushort VK_KEY_N = 0x4E;
    public const ushort VK_KEY_O = 0x4F;
    public const ushort VK_KEY_Q = 0x51;
    public const ushort VK_KEY_S = 0x53;
    public const ushort VK_KEY_T = 0x54;
    public const ushort VK_KEY_V = 0x56;
    public const ushort VK_KEY_X = 0x58;
    public const ushort VK_KEY_Z = 0x5A;

    public const ushort VK_F9 = 0x78;
    public const ushort VK_F10 = 0x79;
    public const ushort VK_F11 = 0x7A;
    public const ushort VK_F12 = 0x7B;

    public const ushort VK_OEM_PLUS = 0xBB;
    public const ushort VK_OEM_COMMA = 0xBC;  // ','
    public const ushort VK_OEM_MINUS = 0xBD;
    public const ushort VK_OEM_PERIOD = 0xBE; // '.'
    public const ushort VK_OEM_2 = 0xBF;      // '/'
    public const ushort VK_OEM_4 = 0xDB;      // '['
    public const ushort VK_OEM_6 = 0xDD;      // ']'

    public static void SendKey(ushort vk, bool extended = false) {
        INPUT[] inputs = new INPUT[2];
        inputs[0].type = INPUT_KEYBOARD;
        inputs[0].ki.wVk = vk;
        inputs[0].ki.dwFlags = extended ? KEYEVENTF_EXTENDEDKEY : 0;
        inputs[1].type = INPUT_KEYBOARD;
        inputs[1].ki.wVk = vk;
        inputs[1].ki.dwFlags = (extended ? KEYEVENTF_EXTENDEDKEY : 0) | KEYEVENTF_KEYUP;
        SendInput(2, inputs, Marshal.SizeOf(typeof(INPUT)));
    }

    public static void SendModifiedKey(ushort modifier, ushort vk, bool extended = false) {
        INPUT[] inputs = new INPUT[4];
        inputs[0].type = INPUT_KEYBOARD; inputs[0].ki.wVk = modifier; inputs[0].ki.dwFlags = 0;
        inputs[1].type = INPUT_KEYBOARD; inputs[1].ki.wVk = vk; inputs[1].ki.dwFlags = extended ? KEYEVENTF_EXTENDEDKEY : 0;
        inputs[2].type = INPUT_KEYBOARD; inputs[2].ki.wVk = vk; inputs[2].ki.dwFlags = (extended ? KEYEVENTF_EXTENDEDKEY : 0) | KEYEVENTF_KEYUP;
        inputs[3].type = INPUT_KEYBOARD; inputs[3].ki.wVk = modifier; inputs[3].ki.dwFlags = KEYEVENTF_KEYUP;
        SendInput(4, inputs, Marshal.SizeOf(typeof(INPUT)));
    }

    public static void SendTwoModifiedKey(ushort mod1, ushort mod2, ushort vk, bool extended = false) {
        INPUT[] inputs = new INPUT[6];
        inputs[0].type = INPUT_KEYBOARD; inputs[0].ki.wVk = mod1; inputs[0].ki.dwFlags = 0;
        inputs[1].type = INPUT_KEYBOARD; inputs[1].ki.wVk = mod2; inputs[1].ki.dwFlags = 0;
        inputs[2].type = INPUT_KEYBOARD; inputs[2].ki.wVk = vk; inputs[2].ki.dwFlags = extended ? KEYEVENTF_EXTENDEDKEY : 0;

        inputs[3].type = INPUT_KEYBOARD; inputs[3].ki.wVk = vk; inputs[3].ki.dwFlags = (extended ? KEYEVENTF_EXTENDEDKEY : 0) | KEYEVENTF_KEYUP;
        inputs[4].type = INPUT_KEYBOARD; inputs[4].ki.wVk = mod2; inputs[4].ki.dwFlags = KEYEVENTF_KEYUP;
        inputs[5].type = INPUT_KEYBOARD; inputs[5].ki.wVk = mod1; inputs[5].ki.dwFlags = KEYEVENTF_KEYUP;
        SendInput(6, inputs, Marshal.SizeOf(typeof(INPUT)));
    }

    public static void RightClick() {
        mouse_event(MOUSEEVENTF_RIGHTDOWN, 0, 0, 0, UIntPtr.Zero);
        Thread.Sleep(25);
        mouse_event(MOUSEEVENTF_RIGHTUP, 0, 0, 0, UIntPtr.Zero);
    }

    public static volatile bool ShouldStop = false;

    public static void Run() {
        Console.CancelKeyPress += delegate(object sender, ConsoleCancelEventArgs e) {
            e.Cancel = true;
            ShouldStop = true;
        };

        XINPUT_STATE state = new XINPUT_STATE();
        ushort lastButtons = 0;
        bool lastR3Down = false;

        bool backUsedInCombo = false;
        bool lbUsedInCombo = false;
        bool rbUsedInCombo = false;

        uint lastPid = 0;
        bool isResolve = false;

        long lastJogTime = 0;
        long lastZoomTime = 0;
        long lastDpadTime = 0;
        long lastUiTime = 0;

        string lastAction = "Ready";
        string lastStatusMsg = "";

        Stopwatch sw = Stopwatch.StartNew();

        while (!ShouldStop) {
            try {
                long now = sw.ElapsedMilliseconds;

                // Check foreground window
                IntPtr fg = GetForegroundWindow();
                uint currentPid = 0;
                GetWindowThreadProcessId(fg, out currentPid);

                if (currentPid != lastPid) {
                    lastPid = currentPid;
                    try {
                        using (Process p = Process.GetProcessById((int)currentPid)) {
                            isResolve = p.ProcessName.IndexOf("Resolve", StringComparison.OrdinalIgnoreCase) >= 0;
                        }
                    } catch {
                        isResolve = false;
                    }
                }

                // Poll Gamepad (Index 0)
                int res = XInputGetState(0, ref state);

                // Update UI status line every 150ms
                if (now - lastUiTime > 150) {
                    lastUiTime = now;
                    string statusMsg;
                    if (res != 0) {
                        statusMsg = "[Status: CONTROLLER DISCONNECTED] Waiting for Xbox controller...";
                    } else if (!isResolve) {
                        statusMsg = "[Status: WAITING] Switch/Click into DaVinci Resolve to edit!   ";
                    } else {
                        statusMsg = string.Format("[Status: ACTIVE IN DAVINCI] Action: {0,-36}", lastAction);
                    }

                    if (statusMsg != lastStatusMsg) {
                        lastStatusMsg = statusMsg;
                        Console.Write("\r" + statusMsg);
                    }
                }

                if (res != 0) {
                    Thread.Sleep(250);
                    continue;
                }

                // Only send inputs when DaVinci Resolve is the active foreground window
                if (!isResolve) {
                    Thread.Sleep(30);
                    continue;
                }

                ushort buttons = state.Gamepad.wButtons;
                ushort pressed = (ushort)(buttons & ~lastButtons);
                ushort released = (ushort)(~buttons & lastButtons);

                bool isBackHeld = (buttons & BTN_BACK) != 0;
                bool isLbHeld = (buttons & SHOULDER_LEFT) != 0;
                bool isRbHeld = (buttons & SHOULDER_RIGHT) != 0;

                // =============================================================
                // LAYER 1: HOLD BACK (Project, View, & Page Switching)
                // =============================================================
                if (isBackHeld) {
                    if ((pressed & BTN_A) != 0) {
                        SendKey(VK_KEY_Q); // Toggle Source Viewer / Timeline
                        lastAction = "Toggle Source/Timeline (Q)";
                        backUsedInCombo = true;
                    }
                    else if ((pressed & BTN_B) != 0) {
                        SendModifiedKey(VK_CONTROL, VK_KEY_Z); // Undo
                        lastAction = "Undo (Ctrl+Z)";
                        backUsedInCombo = true;
                    }
                    else if ((pressed & BTN_Y) != 0) {
                        SendTwoModifiedKey(VK_CONTROL, VK_SHIFT, VK_KEY_Z); // Redo
                        lastAction = "Redo (Ctrl+Shift+Z)";
                        backUsedInCombo = true;
                    }
                    else if ((pressed & BTN_X) != 0) {
                        SendModifiedKey(VK_MENU, VK_KEY_X); // Clear In/Out (Alt+X)
                        lastAction = "Clear In/Out (Alt+X)";
                        backUsedInCombo = true;
                    }
                    else if ((pressed & BTN_START) != 0) {
                        SendModifiedKey(VK_CONTROL, VK_KEY_S); // Quick Save Project
                        lastAction = "Quick Save Project (Ctrl+S)";
                        backUsedInCombo = true;
                    }
                    else if ((pressed & THUMB_RIGHT) != 0) {
                        SendModifiedKey(VK_CONTROL, VK_KEY_F); // Fullscreen Cinema Preview
                        lastAction = "Cinema Fullscreen (Ctrl+F)";
                        backUsedInCombo = true;
                    }
                    else if ((pressed & THUMB_LEFT) != 0) {
                        SendKey(VK_KEY_M); // Add Marker
                        lastAction = "Add Marker (M)";
                        backUsedInCombo = true;
                    }
                    else if ((pressed & SHOULDER_LEFT) != 0) {
                        SendKey(VK_HOME, true); // Jump to Start of Timeline
                        lastAction = "Jump to Timeline Start (Home)";
                        backUsedInCombo = true;
                    }
                    else if ((pressed & SHOULDER_RIGHT) != 0) {
                        SendKey(VK_END, true); // Jump to End of Timeline
                        lastAction = "Jump to Timeline End (End)";
                        backUsedInCombo = true;
                    }
                    else if ((pressed & DPAD_LEFT) != 0) {
                        SendModifiedKey(VK_SHIFT, VK_KEY_3); // Cut Page
                        lastAction = "Switch to Cut Page (Shift+3)";
                        backUsedInCombo = true;
                    }
                    else if ((pressed & DPAD_UP) != 0) {
                        SendModifiedKey(VK_SHIFT, VK_KEY_4); // Edit Page
                        lastAction = "Switch to Edit Page (Shift+4)";
                        backUsedInCombo = true;
                    }
                    else if ((pressed & DPAD_RIGHT) != 0) {
                        SendModifiedKey(VK_SHIFT, VK_KEY_6); // Color Page
                        lastAction = "Switch to Color Page (Shift+6)";
                        backUsedInCombo = true;
                    }
                    else if ((pressed & DPAD_DOWN) != 0) {
                        SendModifiedKey(VK_SHIFT, VK_KEY_8); // Deliver Page
                        lastAction = "Switch to Deliver Page (Shift+8)";
                        backUsedInCombo = true;
                    }
                }
                // Handle BACK release (Tap alone = Zoom Fit)
                else if ((released & BTN_BACK) != 0) {
                    if (!backUsedInCombo) {
                        SendModifiedKey(VK_SHIFT, VK_KEY_Z);
                        lastAction = "Zoom Fit Timeline (Shift+Z)";
                    }
                    backUsedInCombo = false;
                }

                // =============================================================
                // LAYER 2: HOLD LB (Assembly & Edit Insertion Layer)
                // =============================================================
                else if (isLbHeld) {
                    if ((pressed & BTN_A) != 0) {
                        SendModifiedKey(VK_SHIFT, VK_F12); // Append to End of Timeline
                        lastAction = "Append Clip to Timeline (Shift+F12)";
                        lbUsedInCombo = true;
                    }
                    else if ((pressed & BTN_Y) != 0) {
                        SendKey(VK_F10); // Overwrite Clip
                        lastAction = "Overwrite Clip (F10)";
                        lbUsedInCombo = true;
                    }
                    else if ((pressed & BTN_X) != 0) {
                        SendKey(VK_F9); // Insert Clip
                        lastAction = "Insert Clip (F9)";
                        lbUsedInCombo = true;
                    }
                    else if ((pressed & BTN_B) != 0) {
                        SendKey(VK_F11); // Replace Clip
                        lastAction = "Replace Clip (F11)";
                        lbUsedInCombo = true;
                    }
                    else if ((pressed & BTN_START) != 0) {
                        SendTwoModifiedKey(VK_CONTROL, VK_SHIFT, VK_KEY_B); // Blade All Tracks
                        lastAction = "Blade All Tracks (Ctrl+Shift+B)";
                        lbUsedInCombo = true;
                    }
                    else if ((pressed & DPAD_LEFT) != 0) {
                        SendKey(VK_OEM_COMMA); // Nudge 1 Frame Left (,)
                        lastAction = "Nudge Clip 1 Frame Left (,)";
                        lbUsedInCombo = true;
                    }
                    else if ((pressed & DPAD_RIGHT) != 0) {
                        SendKey(VK_OEM_PERIOD); // Nudge 1 Frame Right (.)
                        lastAction = "Nudge Clip 1 Frame Right (.)";
                        lbUsedInCombo = true;
                    }
                    else if ((pressed & DPAD_UP) != 0) {
                        SendModifiedKey(VK_SHIFT, VK_OEM_COMMA); // Nudge 5 Frames Left (Shift + ,)
                        lastAction = "Nudge Clip 5 Frames Left";
                        lbUsedInCombo = true;
                    }
                    else if ((pressed & DPAD_DOWN) != 0) {
                        SendModifiedKey(VK_SHIFT, VK_OEM_PERIOD); // Nudge 5 Frames Right (Shift + .)
                        lastAction = "Nudge Clip 5 Frames Right";
                        lbUsedInCombo = true;
                    }
                }
                // Handle LB release (Tap alone = Shuttle Rewind J)
                else if ((released & SHOULDER_LEFT) != 0) {
                    if (!lbUsedInCombo) {
                        SendKey(VK_KEY_J);
                        lastAction = "Shuttle Rewind (J)";
                    }
                    lbUsedInCombo = false;
                }

                // =============================================================
                // LAYER 3: HOLD RB (Trimming, Transitions & Clip Properties)
                // =============================================================
                else if (isRbHeld) {
                    if ((pressed & BTN_A) != 0) {
                        SendKey(VK_KEY_D); // Enable / Disable Clip
                        lastAction = "Toggle Clip Enable/Disable (D)";
                        rbUsedInCombo = true;
                    }
                    else if ((pressed & BTN_B) != 0) {
                        SendModifiedKey(VK_CONTROL, VK_KEY_T); // Add Default Video Transition (Cross Dissolve)
                        lastAction = "Add Transition (Ctrl+T)";
                        rbUsedInCombo = true;
                    }
                    else if ((pressed & BTN_X) != 0) {
                        SendTwoModifiedKey(VK_CONTROL, VK_SHIFT, VK_KEY_T); // Add Audio Transition
                        lastAction = "Add Audio Transition (Ctrl+Shift+T)";
                        rbUsedInCombo = true;
                    }
                    else if ((pressed & BTN_Y) != 0) {
                        SendKey(VK_KEY_N); // Toggle Snapping On / Off
                        lastAction = "Toggle Snapping (N)";
                        rbUsedInCombo = true;
                    }
                    else if ((pressed & BTN_START) != 0) {
                        SendTwoModifiedKey(VK_CONTROL, VK_SHIFT, VK_KEY_L); // Toggle Linked Selection
                        lastAction = "Toggle Linked Selection";
                        rbUsedInCombo = true;
                    }
                    else if ((pressed & THUMB_RIGHT) != 0) {
                        RightClick(); // Mouse Right Click (Context Menu)
                        lastAction = "Mouse Right Click";
                        rbUsedInCombo = true;
                    }
                    else if ((pressed & DPAD_UP) != 0) {
                        SendTwoModifiedKey(VK_CONTROL, VK_SHIFT, VK_OEM_4); // Ripple Trim Start to Playhead
                        lastAction = "Ripple Trim Start to Playhead";
                        rbUsedInCombo = true;
                    }
                    else if ((pressed & DPAD_DOWN) != 0) {
                        SendTwoModifiedKey(VK_CONTROL, VK_SHIFT, VK_OEM_6); // Ripple Trim End to Playhead
                        lastAction = "Ripple Trim End to Playhead";
                        rbUsedInCombo = true;
                    }
                    else if ((pressed & DPAD_LEFT) != 0) {
                        SendKey(VK_KEY_V); // Select Nearest Edit Point (V)
                        lastAction = "Select Edit Point (V)";
                        rbUsedInCombo = true;
                    }
                    else if ((pressed & DPAD_RIGHT) != 0) {
                        SendModifiedKey(VK_SHIFT, VK_KEY_V); // Select Clip under Playhead
                        lastAction = "Select Clip under Playhead";
                        rbUsedInCombo = true;
                    }
                }
                // Handle RB release (Tap alone = Shuttle Forward L)
                else if ((released & SHOULDER_RIGHT) != 0) {
                    if (!rbUsedInCombo) {
                        SendKey(VK_KEY_L);
                        lastAction = "Shuttle Forward (L)";
                    }
                    rbUsedInCombo = false;
                }

                // =============================================================
                // BASE LAYER: No Modifiers Held
                // =============================================================
                else {
                    if ((pressed & BTN_A) != 0) {
                        SendKey(VK_SPACE); // Play / Pause
                        lastAction = "Play / Pause (Space)";
                    }
                    if ((pressed & BTN_B) != 0) {
                        SendModifiedKey(VK_CONTROL, VK_KEY_B); // Blade / Split Clip at Playhead
                        lastAction = "Blade / Split Clip (Ctrl+B)";
                    }
                    if ((pressed & BTN_X) != 0) {
                        SendKey(VK_KEY_I); // Mark In
                        lastAction = "Mark In (I)";
                    }
                    if ((pressed & BTN_Y) != 0) {
                        SendKey(VK_KEY_O); // Mark Out
                        lastAction = "Mark Out (O)";
                    }
                    if ((pressed & THUMB_LEFT) != 0) {
                        SendKey(VK_KEY_K); // Shuttle Stop / Pause (K)
                        lastAction = "Shuttle Stop (K)";
                    }
                    if ((pressed & BTN_START) != 0) {
                        SendKey(VK_DELETE, true); // Ripple Delete selected clip
                        lastAction = "Ripple Delete (Delete)";
                    }

                    // D-PAD: Navigation (Single Frame & Cut Jumps)
                    if ((pressed & DPAD_LEFT) != 0) {
                        SendKey(VK_LEFT, true); // Step 1 Frame Left
                        lastAction = "Step Backward 1 Frame";
                        lastDpadTime = now + 160;
                    } else if ((buttons & DPAD_LEFT) != 0 && now > lastDpadTime) {
                        SendKey(VK_LEFT, true);
                        lastDpadTime = now + 80;
                    }

                    if ((pressed & DPAD_RIGHT) != 0) {
                        SendKey(VK_RIGHT, true); // Step 1 Frame Right
                        lastAction = "Step Forward 1 Frame";
                        lastDpadTime = now + 160;
                    } else if ((buttons & DPAD_RIGHT) != 0 && now > lastDpadTime) {
                        SendKey(VK_RIGHT, true);
                        lastDpadTime = now + 80;
                    }

                    if ((pressed & DPAD_UP) != 0) {
                        SendKey(VK_UP, true); // Jump Previous Cut Point
                        lastAction = "Jump Previous Cut Point";
                    }
                    if ((pressed & DPAD_DOWN) != 0) {
                        SendKey(VK_DOWN, true); // Jump Next Cut Point
                        lastAction = "Jump Next Cut Point";
                    }
                }

                // =============================================================
                // LEFT STICK: Pro Analog Jog Wheel
                // =============================================================
                int lx = (int)state.Gamepad.sThumbLX;
                int absLx = Math.Abs(lx);
                if (absLx > 32767) absLx = 32767;
                const int JOG_DEADZONE = 7000;

                if (absLx > JOG_DEADZONE) {
                    float intensity = (float)(absLx - JOG_DEADZONE) / (32767f - JOG_DEADZONE);
                    if (intensity > 1.0f) intensity = 1.0f;
                    int interval = (int)(260f - (intensity * 235f));
                    if (interval < 25) interval = 25;

                    if (now - lastJogTime >= interval) {
                        lastJogTime = now;
                        if (lx < 0) {
                            SendKey(VK_LEFT, true);
                            lastAction = string.Format("Jog Rewind ({0} ms)", interval);
                        } else {
                            SendKey(VK_RIGHT, true);
                            lastAction = string.Format("Jog Forward ({0} ms)", interval);
                        }
                    }
                }

                // =============================================================
                // TRIGGERS: Smooth Timeline Zoom
                // =============================================================
                byte lt = state.Gamepad.bLeftTrigger;
                byte rt = state.Gamepad.bRightTrigger;
                const byte TRIGGER_THRESHOLD = 40;

                if (lt > TRIGGER_THRESHOLD && (now - lastZoomTime > 140)) {
                    SendModifiedKey(VK_CONTROL, VK_OEM_MINUS); // Zoom Out
                    lastAction = "Zoom Timeline Out (Ctrl -)";
                    lastZoomTime = now;
                } else if (rt > TRIGGER_THRESHOLD && (now - lastZoomTime > 140)) {
                    SendModifiedKey(VK_CONTROL, VK_OEM_PLUS); // Zoom In
                    lastAction = "Zoom Timeline In (Ctrl +)";
                    lastZoomTime = now;
                }

                // =============================================================
                // RIGHT STICK: Smooth Mouse Emulation
                // =============================================================
                int rx = (int)state.Gamepad.sThumbRX;
                int ry = (int)state.Gamepad.sThumbRY;
                int absRx = Math.Abs(rx);
                int absRy = Math.Abs(ry);
                if (absRx > 32767) absRx = 32767;
                if (absRy > 32767) absRy = 32767;
                const int MOUSE_DEADZONE = 6000;

                if (absRx > MOUSE_DEADZONE || absRy > MOUSE_DEADZONE) {
                    float factorX = 0f;
                    float factorY = 0f;

                    if (absRx > MOUSE_DEADZONE) {
                        float normX = (float)(absRx - MOUSE_DEADZONE) / (32767f - MOUSE_DEADZONE);
                        if (normX > 1.0f) normX = 1.0f;
                        factorX = Math.Sign(rx) * (float)Math.Pow(normX, 1.6) * 20f;
                    }
                    if (absRy > MOUSE_DEADZONE) {
                        float normY = (float)(absRy - MOUSE_DEADZONE) / (32767f - MOUSE_DEADZONE);
                        if (normY > 1.0f) normY = 1.0f;
                        factorY = -Math.Sign(ry) * (float)Math.Pow(normY, 1.6) * 20f; // Invert Y
                    }

                    mouse_event(MOUSEEVENTF_MOVE, (int)factorX, (int)factorY, 0, UIntPtr.Zero);
                }

                // R3: Left Mouse Click (when RB is not held for Right Click)
                bool isR3Down = (buttons & THUMB_RIGHT) != 0;
                if (!isRbHeld && !isBackHeld) {
                    if (isR3Down && !lastR3Down) {
                        mouse_event(MOUSEEVENTF_LEFTDOWN, 0, 0, 0, UIntPtr.Zero);
                        lastAction = "Mouse Left Down";
                    } else if (!isR3Down && lastR3Down) {
                        mouse_event(MOUSEEVENTF_LEFTUP, 0, 0, 0, UIntPtr.Zero);
                        lastAction = "Mouse Left Up";
                    }
                }
                lastR3Down = isR3Down;

                lastButtons = buttons;
            } catch (Exception ex) {
                lastAction = "Handled: " + ex.Message;
            }

            Thread.Sleep(8); // ~120Hz polling rate for ultra-low latency
        }

        Console.WriteLine("\n[Gamepad Engine Stopped gracefully]");
    }
}
"@

Add-Type -TypeDefinition $source

Clear-Host
Write-Host "=========================================================================" -ForegroundColor Cyan
Write-Host "         DaVinci Resolve - 100% Assembly Gamepad Hub Active              " -ForegroundColor Yellow
Write-Host "=========================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host " 1. BASE LAYER (Normal Press):" -ForegroundColor Green
Write-Host "   * [Left Stick]         : Pro Jog Wheel (variable scrub from slow to 40 fps)"
Write-Host "   * [A]                  : Play / Pause (Space)"
Write-Host "   * [B]                  : Blade / Split Clip at Playhead (Ctrl+B)"
Write-Host "   * [X] / [Y]            : Mark In (I) / Mark Out (O)"
Write-Host "   * [Start]              : Ripple Delete (Delete)"
Write-Host "   * [LB] / [RB] (Tap)    : Shuttle Rewind (J) / Fast Forward (L)"
Write-Host "   * [L3 (Stick Click)]   : Shuttle Stop / Pause (K)"
Write-Host "   * [D-Pad Left / Right] : Step 1 Frame Backward / Forward"
Write-Host "   * [D-Pad Up / Down]    : Jump to Previous / Next Cut Point"
Write-Host "   * [LT / RT Triggers]   : Smooth Timeline Zoom Out / In"
Write-Host "   * [Right Stick / R3]   : Smooth Mouse Cursor / Left Click"
Write-Host ""
Write-Host " 2. ASSEMBLY & INSERTION (Hold [LB] + Tap):" -ForegroundColor Green
Write-Host "   * [LB + A]             : APPEND Clip to End of Timeline (Shift+F12)" -ForegroundColor White
Write-Host "   * [LB + Y]             : OVERWRITE Clip to Timeline (F10)" -ForegroundColor White
Write-Host "   * [LB + X]             : INSERT Clip into Timeline (F9)" -ForegroundColor White
Write-Host "   * [LB + B]             : REPLACE Clip (F11)" -ForegroundColor White
Write-Host "   * [LB + Start]         : BLADE ALL TRACKS (Ctrl+Shift+B)" -ForegroundColor White
Write-Host "   * [LB + D-Pad Left/Rt] : NUDGE Clip 1 Frame Left / Right (, / .)" -ForegroundColor White
Write-Host "   * [LB + D-Pad Up/Down] : NUDGE Clip 5 Frames Left / Right (Shift + , / .)" -ForegroundColor White
Write-Host ""
Write-Host " 3. TRIMMING, TRANSITIONS & AUDIO (Hold [RB] + Tap):" -ForegroundColor Green
Write-Host "   * [RB + B]             : Add Video Transition / Cross Dissolve (Ctrl+T)" -ForegroundColor White
Write-Host "   * [RB + X]             : Add Audio Transition / Crossfade (Ctrl+Shift+T)" -ForegroundColor White
Write-Host "   * [RB + A]             : Enable / Disable Clip (D) [audition B-roll]" -ForegroundColor White
Write-Host "   * [RB + Y]             : Toggle Snapping On / Off (N)" -ForegroundColor White
Write-Host "   * [RB + D-Pad Up/Down] : Ripple Trim Start / End to Playhead" -ForegroundColor White
Write-Host "   * [RB + D-Pad Left/Rt] : Select Nearest Cut (V) / Select Clip (Shift+V)" -ForegroundColor White
Write-Host "   * [RB + Start]         : Toggle Linked Selection (Ctrl+Shift+L)" -ForegroundColor White
Write-Host "   * [RB + R3]            : Mouse RIGHT-CLICK (Context Menu)" -ForegroundColor White
Write-Host ""
Write-Host " 4. WORKSPACE & PROJECT (Hold [Back] + Tap):" -ForegroundColor Green
Write-Host "   * [Back Tap alone]     : Fit Entire Timeline to Window (Shift+Z)" -ForegroundColor White
Write-Host "   * [Back + A]           : Toggle Source Viewer / Timeline (Q)" -ForegroundColor White
Write-Host "   * [Back + B] / [Y]     : Undo (Ctrl+Z) / Redo (Ctrl+Shift+Z)" -ForegroundColor White
Write-Host "   * [Back + X]           : Clear In & Out Points (Alt+X)" -ForegroundColor White
Write-Host "   * [Back + Start]       : QUICK SAVE Project (Ctrl+S)" -ForegroundColor White
Write-Host "   * [Back + R3]          : Fullscreen Cinema Preview (Ctrl+F)" -ForegroundColor White
Write-Host "   * [Back + L3]          : Add Marker (M)" -ForegroundColor White
Write-Host "   * [Back + LB] / [RB]   : Jump to Start (Home) / Jump to End (End)" -ForegroundColor White
Write-Host "   * [Back + D-Pad]       : Left=Cut Page | Up=Edit Page | Rt=Color | Down=Deliver" -ForegroundColor White
Write-Host ""
Write-Host "-------------------------------------------------------------------------" -ForegroundColor Cyan
Write-Host "Active. Switch or click into DaVinci Resolve to begin editing!" -ForegroundColor Magenta
Write-Host ""

# Run the engine directly on the main thread (100% reliable)
[DaVinciAssemblyEngine]::Run()
