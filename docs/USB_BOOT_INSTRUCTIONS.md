## USB Boot Instructions

### Quick Reference Card

**Workshop WiFi:** `CODE_CRISPIES` / Password: `scienceinthecity2025`

---

## How to Boot from USB Drive

### Step 1: Insert USB Drive
- Insert the CODE CRISPIES workshop USB drive
- Do NOT remove it until workshop ends

### Step 2: Boot from USB

#### Desktop PC / Most Laptops
1. **Restart** your computer
2. **Press and HOLD** one of these keys immediately as it starts:
   - `F12` (most common)
   - `F11` 
   - `F9`
   - `ESC`
3. Select **USB Drive** or **UEFI: USB Drive** from boot menu
4. Press `Enter`

#### Mac (Intel)
1. **Restart** your Mac
2. **Press and HOLD** `Option` (⌥) key immediately
3. Select the **USB drive** (may show as "EFI Boot")
4. Press `Enter`

#### Mac (Apple Silicon M1/M2)
1. **Shut down** completely
2. **Press and HOLD** the power button until you see startup options
3. Select the **USB drive** option
4. Click **Continue**

#### If Boot Menu Doesn't Appear

**Windows PC:**
1. Boot into Windows
2. Hold `Shift` + click **Restart**
3. Choose **Troubleshoot** → **Advanced** → **UEFI Firmware**
4. Find **Boot Order** settings
5. Move **USB Drive** to top of list
6. Save and exit

**Popular Manufacturer Keys:**
- **Dell:** `F12`
- **HP:** `F9` or `ESC` then `F9`
- **Lenovo:** `F12` or `Fn + F12`
- **ASUS:** `F8` or `ESC`
- **Acer:** `F12`
- **MSI:** `F11`
- **Samsung:** `F2` then navigate to Boot tab
- **Toshiba:** `F12`

---

## What You Should See

1. **NixOS Boot Screen** appears
2. System loads (takes 30-60 seconds)
3. **Desktop environment** starts automatically
4. **GNOME desktop appears** (terminal does not auto-open)
5. Open terminal manually: click terminal icon or press `Ctrl + Alt + T`

---

## Getting Started Commands

```bash
# WiFi connects automatically - no manual setup needed!
# Set up your local environment
setup

# See available app recipes
recipes

# Get help
help
```

---

## Mobile Hotspot Instructions
**If WiFi isn't working:**

**iPhone:**
Settings → Personal Hotspot → Turn On
Name: iPhone, Password: (ask facilitator)

**Android:**
Settings → Network → Hotspot & Tethering → Mobile Hotspot
Name: Android, Password: (ask facilitator)

---

## Troubleshooting

**"No bootable device"**
→ Try different F-key (F11, F9, ESC)
→ USB drive may not be properly inserted

**Mac won't boot USB**  
→ USB drive might need to be reformatted for Mac
→ Ask facilitator for Mac-compatible USB

**Boots to Windows/Mac instead**
→ You didn't press the boot key fast enough
→ Restart and try again immediately

**Terminal doesn't open automatically**
→ Click terminal icon in taskbar (GNOME Console)
→ Or press `Ctrl + Alt + T`
→ Note: Terminal no longer auto-starts to prevent boot hangs

**Can't connect to internet**
→ WiFi should connect automatically to "CODE_CRISPIES"
→ If not, use mobile hotspot as backup
→ Check: nmcli connection show --active
