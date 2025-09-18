# 🔧 SCAI System App Installation Guide

## ⚠️ **Critical Limitation: Call Recording Requires System App Status**

The SCAI Flutter app currently records **microphone audio only** because Android restricts call recording to system apps. To enable **full call recording** (both sides of conversation), the app must be installed as a system app.

## 🚨 **Current Behavior (User App)**

- ✅ **Phone state detection** - Works perfectly
- ✅ **Automatic recording triggers** - Works perfectly  
- ⚠️ **Audio recording** - **Microphone only** (user's voice)
- ❌ **Full call recording** - **Not available** (requires system app)

## 🛠️ **Solution: Convert to System App**

### **Prerequisites:**
- Rooted Android device
- ADB (Android Debug Bridge) installed
- USB debugging enabled
- SCAI APK file

### **Step 1: Prepare the APK**
```bash
# Build the release APK
flutter build apk --release

# Copy APK to accessible location
cp build/app/outputs/flutter-apk/app-release.apk ~/Desktop/scai-app.apk
```

### **Step 2: Root Access Required**
```bash
# Enable root access
adb shell
su

# Remount system partition as writable
mount -o remount,rw /system
```

### **Step 3: Install as System App**
```bash
# Create system app directory
mkdir -p /system/app/SCAI

# Copy APK to system directory
cp /sdcard/scai-app.apk /system/app/SCAI/SCAI.apk

# Set proper permissions
chmod 644 /system/app/SCAI/SCAI.apk
chown root:root /system/app/SCAI/SCAI.apk

# Remount system as read-only
mount -o remount,ro /system
```

### **Step 4: Reboot and Verify**
```bash
# Reboot device
reboot

# After reboot, verify installation
adb shell pm list packages | grep scai
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
