<#
================================================================================
DaVinci Resolve Gamepad Hub — Config-Driven Edition
All button mappings and tuning values now live in bindings.json (same folder).
Edit that file to remap anything — no PowerShell/C# editing or recompiling.
================================================================================
#>

$ScriptDir  = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
$ConfigPath = Join-Path $ScriptDir "bindings.json"

# ------------------------------------------------------------------------------
# Default config, written to disk on first run if bindings.json is missing.
# ------------------------------------------------------------------------------
$DefaultConfigJson = @'
{
  "settings": {
    "pollIntervalMs": 8,
    "statusRefreshMs": 150,
    "disconnectedRetryMs": 250,
    "inactiveAppSleepMs": 30,
    "jogDeadzone": 7000,
    "jogMaxIntervalMs": 260,
    "jogMinIntervalMs": 25,
    "mouseDeadzone": 6000,
    "mouseSensitivity": 20,
    "mouseCurveExponent": 1.6,
    "triggerThreshold": 40,
    "zoomCooldownMs": 140,
    "dpadRepeatInitialMs": 160,
    "dpadRepeatMs": 80
  },
  "bindings": {
    "Base": {
      "A":         { "keys": "Space",  "label": "Play / Pause" },
      "B":         { "keys": "Ctrl B", "label": "Blade / Split Clip at Playhead" },
      "X":         { "keys": "I",      "label": "Mark In" },
      "Y":         { "keys": "O",      "label": "Mark Out" },
      "L3":        { "keys": "K",      "label": "Shuttle Stop / Pause" },
      "Start":     { "keys": "Delete", "label": "Ripple Delete" },
      "DPadLeft":  { "keys": "Left",   "label": "Step Backward 1 Frame" },
      "DPadRight": { "keys": "Right",  "label": "Step Forward 1 Frame" },
      "DPadUp":    { "keys": "Up",     "label": "Jump Previous Cut Point" },
      "DPadDown":  { "keys": "Down",   "label": "Jump Next Cut Point" }
    },
    "Tap": {
      "LB":   { "keys": "J",       "label": "Shuttle Rewind" },
      "RB":   { "keys": "L",       "label": "Shuttle Forward" },
      "Back": { "keys": "Shift Z", "label": "Fit Timeline to Window" }
    },
    "LB": {
      "A":         { "keys": "Shift F12",    "label": "Append Clip to End of Timeline" },
      "Y":         { "keys": "F10",          "label": "Overwrite Clip to Timeline" },
      "X":         { "keys": "F9",           "label": "Insert Clip into Timeline" },
      "B":         { "keys": "F11",          "label": "Replace Clip" },
      "Start":     { "keys": "Ctrl Shift B", "label": "Blade All Tracks" },
      "DPadLeft":  { "keys": ",",            "label": "Nudge Clip 1 Frame Left" },
      "DPadRight": { "keys": ".",            "label": "Nudge Clip 1 Frame Right" },
      "DPadUp":    { "keys": "Shift ,",      "label": "Nudge Clip 5 Frames Left" },
      "DPadDown":  { "keys": "Shift .",      "label": "Nudge Clip 5 Frames Right" }
    },
    "RB": {
      "A":         { "keys": "D",            "label": "Toggle Clip Enable/Disable" },
      "B":         { "keys": "Ctrl T",       "label": "Add Video Transition (Cross Dissolve)" },
      "X":         { "keys": "Ctrl Shift T", "label": "Add Audio Transition (Crossfade)" },
      "Y":         { "keys": "N",            "label": "Toggle Snapping" },
      "Start":     { "keys": "Ctrl Shift L", "label": "Toggle Linked Selection" },
      "DPadUp":    { "keys": "Ctrl Shift [", "label": "Ripple Trim Start to Playhead" },
      "DPadDown":  { "keys": "Ctrl Shift ]", "label": "Ripple Trim End to Playhead" },
      "DPadLeft":  { "keys": "V",            "label": "Select Nearest Edit Point" },
      "DPadRight": { "keys": "Shift V",      "label": "Select Clip under Playhead" },
      "R3":        { "keys": "MOUSE_RIGHT_CLICK", "label": "Mouse Right-Click (Context Menu)" }
    },
    "Back": {
      "A":         { "keys": "Q",       "label": "Toggle Source Viewer / Timeline" },
      "B":         { "keys": "Ctrl Z",  "label": "Undo" },
      "Y":         { "keys": "Ctrl Shift Z", "label": "Redo" },
      "X":         { "keys": "Alt X",   "label": "Clear In & Out Points" },
      "Start":     { "keys": "Ctrl S",  "label": "Quick Save Project" },
      "R3":        { "keys": "Ctrl F",  "label": "Fullscreen Cinema Preview" },
      "L3":        { "keys": "M",       "label": "Add Marker" },
      "LB":        { "keys": "Home",    "label": "Jump to Timeline Start" },
      "RB":        { "keys": "End",     "label": "Jump to Timeline End" },
      "DPadLeft":  { "keys": "Shift 3", "label": "Switch to Cut Page" },
      "DPadUp":    { "keys": "Shift 4", "label": "Switch to Edit Page" },
      "DPadRight": { "keys": "Shift 6", "label": "Switch to Color Page" },
      "DPadDown":  { "keys": "Shift 8", "label": "Switch to Deliver Page" }
    },
    "Trigger": {
      "Left":  { "keys": "Ctrl -", "label": "Zoom Timeline Out" },
      "Right": { "keys": "Ctrl +", "label": "Zoom Timeline In" }
    }
  }
}
'@

if (-not (Test-Path $ConfigPath)) {
    Write-Host "No bindings.json found — writing default config to $ConfigPath" -ForegroundColor Yellow
    Set-Content -Path $ConfigPath -Value $DefaultConfigJson -Encoding UTF8
}

try {
    $Config = Get-Content -Path $ConfigPath -Raw | ConvertFrom-Json
} catch {
    Write-Host "bindings.json failed to parse ($($_.Exception.Message)) — falling back to built-in defaults." -ForegroundColor Red
    $Config = $DefaultConfigJson | ConvertFrom-Json
}

# ------------------------------------------------------------------------------
# The engine itself. Mapping tables and analog tuning are populated after
# Add-Type from the parsed JSON above — no bindings are hardcoded here anymore.
# ------------------------------------------------------------------------------
$source = @"
using System;
using System.Collections.Generic;
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

    public const ushort VK_CONTROL = 0x11;
    public const ushort VK_SHIFT = 0x10;
    public const ushort VK_MENU = 0x12; // Alt

    // ---------------------------------------------------------------------
    // Data-driven mapping tables. Populated by LoadBinding()/SetSetting()
    // calls made from PowerShell right after Add-Type, from bindings.json.
    // ---------------------------------------------------------------------
    public static Dictionary<string, string> Bindings = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
    public static Dictionary<string, string> Labels = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
    public static Dictionary<string, double> Settings = new Dictionary<string, double>(StringComparer.OrdinalIgnoreCase);

    public static Dictionary<string, ushort> KeyMap = new Dictionary<string, ushort>(StringComparer.OrdinalIgnoreCase) {
        {"SPACE", 0x20}, {"ENTER", 0x0D}, {"RETURN", 0x0D}, {"TAB", 0x09}, {"BACKSPACE", 0x08},
        {"ESC", 0x1B}, {"ESCAPE", 0x1B},
        {"LEFT", 0x25}, {"UP", 0x26}, {"RIGHT", 0x27}, {"DOWN", 0x28},
        {"HOME", 0x24}, {"END", 0x23}, {"DELETE", 0x2E}, {"INSERT", 0x2D},
        {"PAGEUP", 0x21}, {"PAGEDOWN", 0x22},
        {"F1",0x70},{"F2",0x71},{"F3",0x72},{"F4",0x73},{"F5",0x74},{"F6",0x75},
        {"F7",0x76},{"F8",0x77},{"F9",0x78},{"F10",0x79},{"F11",0x7A},{"F12",0x7B},
        {",", 0xBC}, {".", 0xBE}, {"-", 0xBD}, {"+", 0xBB}, {"/", 0xBF}, {"[", 0xDB}, {"]", 0xDD}
    };

    public static Dictionary<string, ushort> ModifierMap = new Dictionary<string, ushort>(StringComparer.OrdinalIgnoreCase) {
        {"CTRL", VK_CONTROL}, {"CONTROL", VK_CONTROL},
        {"SHIFT", VK_SHIFT},
        {"ALT", VK_MENU}, {"MENU", VK_MENU}
    };

    public static HashSet<string> ExtendedKeys = new HashSet<string>(StringComparer.OrdinalIgnoreCase) {
        "LEFT", "RIGHT", "UP", "DOWN", "HOME", "END", "DELETE", "INSERT", "PAGEUP", "PAGEDOWN"
    };

    public static void AddBinding(string key, string keys, string label) {
        Bindings[key] = keys;
        Labels[key] = label;
    }

    public static void SetSetting(string name, double value) {
        Settings[name] = value;
    }

    public static double GetSetting(string name, double fallback) {
        double v;
        return Settings.TryGetValue(name, out v) ? v : fallback;
    }

    public static bool ResolveKey(string token, out ushort vk) {
        if (KeyMap.TryGetValue(token, out vk)) return true;
        if (token.Length == 1) {
            char c = char.ToUpperInvariant(token[0]);
            if (c >= 'A' && c <= 'Z') { vk = (ushort)c; return true; }
            if (c >= '0' && c <= '9') { vk = (ushort)c; return true; }
        }
        vk = 0;
        return false;
    }

    public static void SendComboKeys(List<ushort> mods, ushort vk, bool extended) {
        int n = mods.Count + 1;
        INPUT[] inputs = new INPUT[n * 2];
        int idx = 0;
        for (int i = 0; i < mods.Count; i++) {
            inputs[idx].type = INPUT_KEYBOARD;
            inputs[idx].ki.wVk = mods[i];
            inputs[idx].ki.dwFlags = 0;
            idx++;
        }
        inputs[idx].type = INPUT_KEYBOARD;
        inputs[idx].ki.wVk = vk;
        inputs[idx].ki.dwFlags = extended ? KEYEVENTF_EXTENDEDKEY : 0;
        idx++;
        inputs[idx].type = INPUT_KEYBOARD;
        inputs[idx].ki.wVk = vk;
        inputs[idx].ki.dwFlags = (extended ? KEYEVENTF_EXTENDEDKEY : 0) | KEYEVENTF_KEYUP;
        idx++;
        for (int i = mods.Count - 1; i >= 0; i--) {
            inputs[idx].type = INPUT_KEYBOARD;
            inputs[idx].ki.wVk = mods[i];
            inputs[idx].ki.dwFlags = KEYEVENTF_KEYUP;
            idx++;
        }
        SendInput((uint)inputs.Length, inputs, Marshal.SizeOf(typeof(INPUT)));
    }

    public static void RightClick() {
        mouse_event(MOUSEEVENTF_RIGHTDOWN, 0, 0, 0, UIntPtr.Zero);
        Thread.Sleep(25);
        mouse_event(MOUSEEVENTF_RIGHTUP, 0, 0, 0, UIntPtr.Zero);
    }

    // Parses a space-separated combo spec like "Ctrl Shift B" or "Left" or
    // "MOUSE_RIGHT_CLICK", and executes it.
    public static void SendCombo(string spec) {
        if (string.IsNullOrEmpty(spec)) return;
        if (spec == "MOUSE_RIGHT_CLICK") { RightClick(); return; }
        if (spec == "MOUSE_LEFT_HOLD") { return; } // handled by the R3 hold logic directly

        string[] parts = spec.Trim().Split(new char[] { ' ' }, StringSplitOptions.RemoveEmptyEntries);
        if (parts.Length == 0) return;

        string mainTok = parts[parts.Length - 1];
        List<ushort> mods = new List<ushort>();
        for (int i = 0; i < parts.Length - 1; i++) {
            ushort m;
            if (ModifierMap.TryGetValue(parts[i], out m)) mods.Add(m);
        }

        ushort vk;
        if (!ResolveKey(mainTok, out vk)) return;
        bool extended = ExtendedKeys.Contains(mainTok);
        SendComboKeys(mods, vk, extended);
    }

    // Looks up "<layer>.<button>" in Bindings, executes it, and returns the
    // human-readable label for the status line (or null if unbound).
    public static string Dispatch(string layer, string button) {
        string key = layer + "." + button;
        string combo;
        if (!Bindings.TryGetValue(key, out combo)) return null;
        SendCombo(combo);
        string label;
        return Labels.TryGetValue(key, out label) ? label : combo;
    }

    public static string GetCombo(string layer, string button) {
        string key = layer + "." + button;
        string combo;
        return Bindings.TryGetValue(key, out combo) ? combo : null;
    }

    public static volatile bool ShouldStop = false;

    public static void Run() {
        Console.CancelKeyPress += delegate(object sender, ConsoleCancelEventArgs e) {
            e.Cancel = true;
            ShouldStop = true;
        };

        double pollIntervalMs        = GetSetting("pollIntervalMs", 8);
        double statusRefreshMs       = GetSetting("statusRefreshMs", 150);
        double disconnectedRetryMs   = GetSetting("disconnectedRetryMs", 250);
        double inactiveAppSleepMs    = GetSetting("inactiveAppSleepMs", 30);
        double jogDeadzone           = GetSetting("jogDeadzone", 7000);
        double jogMaxIntervalMs      = GetSetting("jogMaxIntervalMs", 260);
        double jogMinIntervalMs      = GetSetting("jogMinIntervalMs", 25);
        double mouseDeadzone         = GetSetting("mouseDeadzone", 6000);
        double mouseSensitivity      = GetSetting("mouseSensitivity", 20);
        double mouseCurveExponent    = GetSetting("mouseCurveExponent", 1.6);
        double triggerThreshold      = GetSetting("triggerThreshold", 40);
        double zoomCooldownMs        = GetSetting("zoomCooldownMs", 140);
        double dpadRepeatInitialMs   = GetSetting("dpadRepeatInitialMs", 160);
        double dpadRepeatMs          = GetSetting("dpadRepeatMs", 80);

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

                if (now - lastUiTime > statusRefreshMs) {
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
                    Thread.Sleep((int)disconnectedRetryMs);
                    continue;
                }

                if (!isResolve) {
                    Thread.Sleep((int)inactiveAppSleepMs);
                    continue;
                }

                ushort buttons = state.Gamepad.wButtons;
                ushort pressed = (ushort)(buttons & ~lastButtons);
                ushort released = (ushort)(~buttons & lastButtons);

                bool isBackHeld = (buttons & BTN_BACK) != 0;
                bool isLbHeld = (buttons & SHOULDER_LEFT) != 0;
                bool isRbHeld = (buttons & SHOULDER_RIGHT) != 0;

                string r;

                // =============================================================
                // LAYER 1: HOLD BACK (Project, View, & Page Switching)
                // =============================================================
                if (isBackHeld) {
                    if ((pressed & BTN_A) != 0)      { if ((r = Dispatch("Back", "A")) != null) lastAction = r; backUsedInCombo = true; }
                    else if ((pressed & BTN_B) != 0) { if ((r = Dispatch("Back", "B")) != null) lastAction = r; backUsedInCombo = true; }
                    else if ((pressed & BTN_Y) != 0) { if ((r = Dispatch("Back", "Y")) != null) lastAction = r; backUsedInCombo = true; }
                    else if ((pressed & BTN_X) != 0) { if ((r = Dispatch("Back", "X")) != null) lastAction = r; backUsedInCombo = true; }
                    else if ((pressed & BTN_START) != 0) { if ((r = Dispatch("Back", "Start")) != null) lastAction = r; backUsedInCombo = true; }
                    else if ((pressed & THUMB_RIGHT) != 0) { if ((r = Dispatch("Back", "R3")) != null) lastAction = r; backUsedInCombo = true; }
                    else if ((pressed & THUMB_LEFT) != 0) { if ((r = Dispatch("Back", "L3")) != null) lastAction = r; backUsedInCombo = true; }
                    else if ((pressed & SHOULDER_LEFT) != 0) { if ((r = Dispatch("Back", "LB")) != null) lastAction = r; backUsedInCombo = true; }
                    else if ((pressed & SHOULDER_RIGHT) != 0) { if ((r = Dispatch("Back", "RB")) != null) lastAction = r; backUsedInCombo = true; }
                    else if ((pressed & DPAD_LEFT) != 0) { if ((r = Dispatch("Back", "DPadLeft")) != null) lastAction = r; backUsedInCombo = true; }
                    else if ((pressed & DPAD_UP) != 0) { if ((r = Dispatch("Back", "DPadUp")) != null) lastAction = r; backUsedInCombo = true; }
                    else if ((pressed & DPAD_RIGHT) != 0) { if ((r = Dispatch("Back", "DPadRight")) != null) lastAction = r; backUsedInCombo = true; }
                    else if ((pressed & DPAD_DOWN) != 0) { if ((r = Dispatch("Back", "DPadDown")) != null) lastAction = r; backUsedInCombo = true; }
                }
                // Handle Back release (Tap alone = Fit Timeline to Window)
                else if ((released & BTN_BACK) != 0) {
                    if (!backUsedInCombo) { if ((r = Dispatch("Tap", "Back")) != null) lastAction = r; }
                    backUsedInCombo = false;
                }

                // =============================================================
                // LAYER 2: HOLD LB (Assembly & Insertion)
                // =============================================================
                else if (isLbHeld) {
                    if ((pressed & BTN_A) != 0) { if ((r = Dispatch("LB", "A")) != null) lastAction = r; lbUsedInCombo = true; }
                    else if ((pressed & BTN_Y) != 0) { if ((r = Dispatch("LB", "Y")) != null) lastAction = r; lbUsedInCombo = true; }
                    else if ((pressed & BTN_X) != 0) { if ((r = Dispatch("LB", "X")) != null) lastAction = r; lbUsedInCombo = true; }
                    else if ((pressed & BTN_B) != 0) { if ((r = Dispatch("LB", "B")) != null) lastAction = r; lbUsedInCombo = true; }
                    else if ((pressed & BTN_START) != 0) { if ((r = Dispatch("LB", "Start")) != null) lastAction = r; lbUsedInCombo = true; }
                    else if ((pressed & DPAD_LEFT) != 0) { if ((r = Dispatch("LB", "DPadLeft")) != null) lastAction = r; lbUsedInCombo = true; }
                    else if ((pressed & DPAD_RIGHT) != 0) { if ((r = Dispatch("LB", "DPadRight")) != null) lastAction = r; lbUsedInCombo = true; }
                    else if ((pressed & DPAD_UP) != 0) { if ((r = Dispatch("LB", "DPadUp")) != null) lastAction = r; lbUsedInCombo = true; }
                    else if ((pressed & DPAD_DOWN) != 0) { if ((r = Dispatch("LB", "DPadDown")) != null) lastAction = r; lbUsedInCombo = true; }
                }
                // Handle LB release (Tap alone = Shuttle Rewind)
                else if ((released & SHOULDER_LEFT) != 0) {
                    if (!lbUsedInCombo) { if ((r = Dispatch("Tap", "LB")) != null) lastAction = r; }
                    lbUsedInCombo = false;
                }

                // =============================================================
                // LAYER 3: HOLD RB (Trimming, Transitions & Clip Properties)
                // =============================================================
                else if (isRbHeld) {
                    if ((pressed & BTN_A) != 0) { if ((r = Dispatch("RB", "A")) != null) lastAction = r; rbUsedInCombo = true; }
                    else if ((pressed & BTN_B) != 0) { if ((r = Dispatch("RB", "B")) != null) lastAction = r; rbUsedInCombo = true; }
                    else if ((pressed & BTN_X) != 0) { if ((r = Dispatch("RB", "X")) != null) lastAction = r; rbUsedInCombo = true; }
                    else if ((pressed & BTN_Y) != 0) { if ((r = Dispatch("RB", "Y")) != null) lastAction = r; rbUsedInCombo = true; }
                    else if ((pressed & BTN_START) != 0) { if ((r = Dispatch("RB", "Start")) != null) lastAction = r; rbUsedInCombo = true; }
                    else if ((pressed & THUMB_RIGHT) != 0) { if ((r = Dispatch("RB", "R3")) != null) lastAction = r; rbUsedInCombo = true; }
                    else if ((pressed & DPAD_UP) != 0) { if ((r = Dispatch("RB", "DPadUp")) != null) lastAction = r; rbUsedInCombo = true; }
                    else if ((pressed & DPAD_DOWN) != 0) { if ((r = Dispatch("RB", "DPadDown")) != null) lastAction = r; rbUsedInCombo = true; }
                    else if ((pressed & DPAD_LEFT) != 0) { if ((r = Dispatch("RB", "DPadLeft")) != null) lastAction = r; rbUsedInCombo = true; }
                    else if ((pressed & DPAD_RIGHT) != 0) { if ((r = Dispatch("RB", "DPadRight")) != null) lastAction = r; rbUsedInCombo = true; }
                }
                // Handle RB release (Tap alone = Shuttle Forward)
                else if ((released & SHOULDER_RIGHT) != 0) {
                    if (!rbUsedInCombo) { if ((r = Dispatch("Tap", "RB")) != null) lastAction = r; }
                    rbUsedInCombo = false;
                }

                // =============================================================
                // BASE LAYER: No Modifiers Held
                // =============================================================
                else {
                    if ((pressed & BTN_A) != 0) { if ((r = Dispatch("Base", "A")) != null) lastAction = r; }
                    if ((pressed & BTN_B) != 0) { if ((r = Dispatch("Base", "B")) != null) lastAction = r; }
                    if ((pressed & BTN_X) != 0) { if ((r = Dispatch("Base", "X")) != null) lastAction = r; }
                    if ((pressed & BTN_Y) != 0) { if ((r = Dispatch("Base", "Y")) != null) lastAction = r; }
                    if ((pressed & THUMB_LEFT) != 0) { if ((r = Dispatch("Base", "L3")) != null) lastAction = r; }
                    if ((pressed & BTN_START) != 0) { if ((r = Dispatch("Base", "Start")) != null) lastAction = r; }

                    // D-PAD: Step Left/Right repeat while held; Up/Down are single jumps
                    if ((pressed & DPAD_LEFT) != 0) {
                        if ((r = Dispatch("Base", "DPadLeft")) != null) lastAction = r;
                        lastDpadTime = now + (long)dpadRepeatInitialMs;
                    } else if ((buttons & DPAD_LEFT) != 0 && now > lastDpadTime) {
                        SendCombo(GetCombo("Base", "DPadLeft"));
                        lastDpadTime = now + (long)dpadRepeatMs;
                    }

                    if ((pressed & DPAD_RIGHT) != 0) {
                        if ((r = Dispatch("Base", "DPadRight")) != null) lastAction = r;
                        lastDpadTime = now + (long)dpadRepeatInitialMs;
                    } else if ((buttons & DPAD_RIGHT) != 0 && now > lastDpadTime) {
                        SendCombo(GetCombo("Base", "DPadRight"));
                        lastDpadTime = now + (long)dpadRepeatMs;
                    }

                    if ((pressed & DPAD_UP) != 0) { if ((r = Dispatch("Base", "DPadUp")) != null) lastAction = r; }
                    if ((pressed & DPAD_DOWN) != 0) { if ((r = Dispatch("Base", "DPadDown")) != null) lastAction = r; }
                }

                // =============================================================
                // LEFT STICK: Pro Analog Jog Wheel (reuses Base.DPadLeft/Right)
                // =============================================================
                int lx = (int)state.Gamepad.sThumbLX;
                int absLx = Math.Abs(lx);
                if (absLx > 32767) absLx = 32767;

                if (absLx > jogDeadzone) {
                    float intensity = (float)((absLx - jogDeadzone) / (32767.0 - jogDeadzone));
                    if (intensity > 1.0f) intensity = 1.0f;
                    int interval = (int)(jogMaxIntervalMs - (intensity * (jogMaxIntervalMs - jogMinIntervalMs)));
                    if (interval < jogMinIntervalMs) interval = (int)jogMinIntervalMs;

                    if (now - lastJogTime >= interval) {
                        lastJogTime = now;
                        if (lx < 0) {
                            SendCombo(GetCombo("Base", "DPadLeft"));
                            lastAction = string.Format("Jog Rewind ({0} ms)", interval);
                        } else {
                            SendCombo(GetCombo("Base", "DPadRight"));
                            lastAction = string.Format("Jog Forward ({0} ms)", interval);
                        }
                    }
                }

                // =============================================================
                // TRIGGERS: Smooth Timeline Zoom
                // =============================================================
                byte lt = state.Gamepad.bLeftTrigger;
                byte rt = state.Gamepad.bRightTrigger;

                if (lt > triggerThreshold && (now - lastZoomTime > zoomCooldownMs)) {
                    if ((r = Dispatch("Trigger", "Left")) != null) lastAction = r;
                    lastZoomTime = now;
                } else if (rt > triggerThreshold && (now - lastZoomTime > zoomCooldownMs)) {
                    if ((r = Dispatch("Trigger", "Right")) != null) lastAction = r;
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

                if (absRx > mouseDeadzone || absRy > mouseDeadzone) {
                    float factorX = 0f;
                    float factorY = 0f;

                    if (absRx > mouseDeadzone) {
                        float normX = (float)((absRx - mouseDeadzone) / (32767.0 - mouseDeadzone));
                        if (normX > 1.0f) normX = 1.0f;
                        factorX = Math.Sign(rx) * (float)Math.Pow(normX, mouseCurveExponent) * (float)mouseSensitivity;
                    }
                    if (absRy > mouseDeadzone) {
                        float normY = (float)((absRy - mouseDeadzone) / (32767.0 - mouseDeadzone));
                        if (normY > 1.0f) normY = 1.0f;
                        factorY = -Math.Sign(ry) * (float)Math.Pow(normY, mouseCurveExponent) * (float)mouseSensitivity;
                    }

                    mouse_event(MOUSEEVENTF_MOVE, (int)factorX, (int)factorY, 0, UIntPtr.Zero);
                }

                // R3: Left Mouse Click (when RB/Back are not held for other R3 uses)
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

            Thread.Sleep((int)pollIntervalMs);
        }

        Console.WriteLine("\n[Gamepad Engine Stopped gracefully]");
    }
}
"@

Add-Type -TypeDefinition $source

# ------------------------------------------------------------------------------
# Push the parsed JSON into the engine's static tables.
# ------------------------------------------------------------------------------
foreach ($settingProp in $Config.settings.PSObject.Properties) {
    [DaVinciAssemblyEngine]::SetSetting($settingProp.Name, [double]$settingProp.Value)
}

foreach ($layerProp in $Config.bindings.PSObject.Properties) {
    $layerName = $layerProp.Name
    foreach ($buttonProp in $layerProp.Value.PSObject.Properties) {
        $buttonName = $buttonProp.Name
        $entry = $buttonProp.Value
        $keyName = "$layerName.$buttonName"
        [DaVinciAssemblyEngine]::AddBinding($keyName, $entry.keys, $entry.label)
    }
}

Clear-Host
Write-Host "=========================================================================" -ForegroundColor Cyan
Write-Host "     DaVinci Resolve - Gamepad Hub Active (config-driven)                " -ForegroundColor Yellow
Write-Host "=========================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Loaded bindings from: $ConfigPath" -ForegroundColor DarkGray
Write-Host "Edit that file and relaunch to remap any button — no code changes needed." -ForegroundColor DarkGray
Write-Host ""
Write-Host " 1. BASE LAYER (Normal Press):" -ForegroundColor Green
Write-Host ("   * [Left Stick]  : Pro Jog Wheel        | [A] {0,-30}" -f [DaVinciAssemblyEngine]::Labels["Base.A"])
Write-Host ("   * [B]           : {0,-24}| [X]/[Y] Mark In / Mark Out" -f [DaVinciAssemblyEngine]::Labels["Base.B"])
Write-Host ("   * [Start]       : {0,-24}| [LB]/[RB] Tap: Shuttle Rewind/Forward" -f [DaVinciAssemblyEngine]::Labels["Base.Start"])
Write-Host "   * [L3]          : Shuttle Stop  | [D-Pad L/R] Frame Step  | [D-Pad U/D] Jump Cut Point"
Write-Host "   * [LT/RT]       : Timeline Zoom | [Right Stick/R3] Mouse Cursor / Left Click"
Write-Host ""
Write-Host " 2. ASSEMBLY & INSERTION (Hold [LB] + Tap):" -ForegroundColor Green
Write-Host ("   * [A] {0} | [Y] {1}" -f [DaVinciAssemblyEngine]::Labels["LB.A"], [DaVinciAssemblyEngine]::Labels["LB.Y"]) -ForegroundColor White
Write-Host ("   * [X] {0} | [B] {1}" -f [DaVinciAssemblyEngine]::Labels["LB.X"], [DaVinciAssemblyEngine]::Labels["LB.B"]) -ForegroundColor White
Write-Host ("   * [Start] {0}" -f [DaVinciAssemblyEngine]::Labels["LB.Start"]) -ForegroundColor White
Write-Host "   * [D-Pad] Nudge Clip 1 / 5 Frames Left-Right" -ForegroundColor White
Write-Host ""
Write-Host " 3. TRIMMING, TRANSITIONS & AUDIO (Hold [RB] + Tap):" -ForegroundColor Green
Write-Host ("   * [B] {0} | [X] {1}" -f [DaVinciAssemblyEngine]::Labels["RB.B"], [DaVinciAssemblyEngine]::Labels["RB.X"]) -ForegroundColor White
Write-Host ("   * [A] {0} | [Y] {1}" -f [DaVinciAssemblyEngine]::Labels["RB.A"], [DaVinciAssemblyEngine]::Labels["RB.Y"]) -ForegroundColor White
Write-Host "   * [D-Pad] Ripple Trim Start/End | Select Nearest Cut / Select Clip" -ForegroundColor White
Write-Host ("   * [Start] {0} | [R3] {1}" -f [DaVinciAssemblyEngine]::Labels["RB.Start"], [DaVinciAssemblyEngine]::Labels["RB.R3"]) -ForegroundColor White
Write-Host ""
Write-Host " 4. WORKSPACE & PROJECT (Hold [Back] + Tap):" -ForegroundColor Green
Write-Host ("   * [Tap alone] {0}" -f [DaVinciAssemblyEngine]::Labels["Tap.Back"]) -ForegroundColor White
Write-Host ("   * [A] {0} | [B]/[Y] Undo / Redo" -f [DaVinciAssemblyEngine]::Labels["Back.A"]) -ForegroundColor White
Write-Host ("   * [X] {0} | [Start] {1}" -f [DaVinciAssemblyEngine]::Labels["Back.X"], [DaVinciAssemblyEngine]::Labels["Back.Start"]) -ForegroundColor White
Write-Host ("   * [R3] {0} | [L3] {1}" -f [DaVinciAssemblyEngine]::Labels["Back.R3"], [DaVinciAssemblyEngine]::Labels["Back.L3"]) -ForegroundColor White
Write-Host "   * [LB]/[RB] Jump to Timeline Start / End" -ForegroundColor White
Write-Host "   * [D-Pad] Left=Cut Page | Up=Edit Page | Right=Color Page | Down=Deliver Page" -ForegroundColor White
Write-Host ""
Write-Host "-------------------------------------------------------------------------" -ForegroundColor Cyan
Write-Host "Active. Switch or click into DaVinci Resolve to begin editing!" -ForegroundColor Magenta
Write-Host ""

# Run the engine directly on the main thread (100% reliable)
[DaVinciAssemblyEngine]::Run()
