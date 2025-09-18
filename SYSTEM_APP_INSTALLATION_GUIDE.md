# SCAI Guard - System App Installation Guide

## Why Convert to System App?

Your SCAI Guard app requires system-level permissions for automatic call recording functionality. Converting it to a system app enables:

- Access to privileged call recording APIs
- Automatic call state monitoring without user intervention
- Enhanced audio recording capabilities during calls
- Bypass of Android's call recording restrictions

## Prerequisites

⚠️ **WARNING**: This process requires rooting your Android device. Proceed at your own risk.

### Required Tools:
- **Rooted Android device** (using Magisk recommended)
- **TWRP Recovery** or **Root file explorer** (like Root Explorer, ES File Explorer)
- **ADB tools** (optional for advanced users)
- **Magisk Manager** (recommended method)

### App Permissions Currently Required:
Your SCAI app uses these permissions that benefit from system-level access:
- `READ_PHONE_STATE` - Monitor call states
- `RECORD_AUDIO` - Record call audio
- `MODIFY_AUDIO_SETTINGS` - Control audio routing
- `READ_CALL_LOG` / `WRITE_CALL_LOG` - Access call history
- `FOREGROUND_SERVICE_PHONE_CALL` - Run during calls

## Installation Methods

### Method 1: Magisk Systemizer (Recommended)

1. **Install Magisk** on your rooted device
2. **Download App Systemizer Module**:
   - Open Magisk Manager
   - Go to Modules section
   - Search for "App Systemizer" or download from [GitHub](https://github.com/Magisk-Modules-Repo/systemize)
   - Install the module

3. **Install Terminal App**:
   - Install Termux from F-Droid or Google Play
   - Grant superuser access when prompted

4. **Systemize SCAI Guard**:
   ```bash
   # Open Termux
   su
   systemize
   ```
   - Select "Systemize Installed Apps"
   - Find and select "SCAI Guard" 
   - Choose installation location: `/system/app`
   - Confirm installation

5. **Reboot** your device

### Method 2: Manual TWRP Method

1. **Prepare App Data**:
   - Install SCAI Guard normally first
   - Use root file explorer to navigate to `/data/app/`
   - Find `com.scai.guard.scai_app-*` folder
   - Copy entire folder to internal storage
   - Rename folder to `SCAIGuard` (remove special characters)

2. **Uninstall Original App**:
   - Uninstall SCAI Guard from device
   - Clear any remaining data

3. **Install via TWRP**:
   - Boot into TWRP Recovery
   - Mount `/system` partition
   - Use TWRP file manager to copy `SCAIGuard` folder to `/system/app/`
   - Set permissions to `755` (rwxr-xr-x)
   - Reboot to system

### Method 3: Manual Root Explorer Method

1. **Copy App Folder**:
   - Use root file explorer with R/W access
   - Navigate to `/data/app/`
   - Find `com.scai.guard.scai_app-*`
   - Copy to `/system/app/`
   - Rename to `SCAIGuard`

2. **Set Permissions**:
   - Long press on folder → Properties
   - Set permissions: Owner: RWX, Group: R-X, Others: R-X (755)
   - Apply to all files and subfolders

3. **Reboot** device

### Method 4: ADB/Root Shell Method

1. **Prepare APK**:
   ```bash
   # Build release APK
   flutter build apk --release
   
   # Push APK to device
   adb push build/app/outputs/flutter-apk/app-release.apk /sdcard/scai-guard.apk
   ```

2. **Install as System App**:
   ```bash
   # Connect via ADB
   adb shell
   su
   
   # Remount system as writable
   mount -o remount,rw /system
   
   # Create system app directory
   mkdir -p /system/app/SCAIGuard
   
   # Copy APK to system
   cp /sdcard/scai-guard.apk /system/app/SCAIGuard/SCAIGuard.apk
   
   # Set permissions
   chmod 644 /system/app/SCAIGuard/SCAIGuard.apk
   chown root:root /system/app/SCAIGuard/SCAIGuard.apk
   
   # Remount as read-only
   mount -o remount,ro /system
   
   # Reboot
   reboot
   ```

## 🔧 **Alternative Solutions (No Root Required)**

### **Option 1: Accessibility Service Approach**
- Use Android Accessibility Service to detect calls
- Record microphone during calls
- Provide clear user notification about limitations

### **Option 2: Call Recording Apps Integration**
- Integrate with existing call recording apps
- Use their APIs if available
- Provide fallback to manual recording

### **Option 3: VoIP Integration**
- Focus on VoIP calls (WhatsApp, Telegram, etc.)
- These can be recorded without system app status
- Expand scam detection to VoIP platforms

## 📱 **Testing System App Installation**

### **Verify Full Call Recording:**
1. Install SCAI as system app (follow steps above)
2. Open SCAI app
3. Enable "Automatic Mode"
4. Make a test call
5. Check recording - should capture both sides

### **Expected Behavior (System App):**
- ✅ **Full call audio** - Both caller and receiver
- ✅ **High quality recording** - Clear audio for analysis
- ✅ **Automatic detection** - No user intervention needed
- ✅ **Background operation** - Works even when app is closed

## ⚡ **Quick Test (Current Implementation)**

### **Test Microphone Recording:**
1. Open SCAI app
2. Go to "Recording Control"
3. Switch to "Manual Mode"
4. Start recording
5. Speak into microphone
6. Stop recording
7. Check "Call History" for saved recording

### **Test Automatic Detection:**
1. Switch to "Automatic Mode"
2. Make a phone call
3. Watch status updates:
   - "📞 Call started - Beginning automatic recording..."
   - "🎙️ Automatic recording in progress..."
   - "📞 Call ended - Stopping automatic recording..."
   - "✅ Recording saved: [filename]"

## 🎯 **Recommendations**

### **For Development/Testing:**
- Use current implementation with microphone recording
- Test all automatic detection features
- Verify scam analysis pipeline works

### **For Production Deployment:**
- Install as system app for full functionality
- Consider partnering with device manufacturers
- Explore alternative recording methods

### **For End Users:**
- Provide clear documentation about limitations
- Offer manual recording as alternative
- Focus on real-time scam detection alerts

## 🔗 **Useful Resources**

- **System App Conversion Guide:** https://droidwin.com/how-to-convert-any-android-app-to-system-app/
- **Android Call Recording Limitations:** https://developer.android.com/guide/topics/media/mediarecorder
- **Root Access Tools:** Magisk, SuperSU
- **ADB Installation:** https://developer.android.com/studio/command-line/adb

## 🚀 **Next Steps**

1. **Test current implementation** with microphone recording
2. **Verify automatic detection** works properly
3. **Consider system app installation** for full functionality
4. **Explore alternative approaches** for non-rooted devices
5. **Focus on real-time scam detection** as primary value proposition

The SCAI app provides excellent **scam detection capabilities** even with microphone-only recording. System app installation unlocks full call recording potential.
