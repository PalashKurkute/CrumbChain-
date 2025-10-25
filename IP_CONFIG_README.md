# 🌐 IP Configuration Management

## Current Configuration

Your IP address is stored in two locations:

1. **Backend**: `backend\.env` → `LOCAL_IP=10.9.31.173`
2. **Flutter**: `lib\config\api_config.dart` → `localIp = '10.9.31.173'`

## Why This Matters

When you're on WiFi or different networks, your local IP address might change. Both your Flutter app and backend need to use the same IP address to communicate.

## 🔄 Automatic IP Update

Run this PowerShell script whenever your IP changes:

```powershell
.\update_ip.ps1
```

This will:
- ✅ Detect your current IP address automatically
- ✅ Update `backend\.env` file
- ✅ Update `lib\config\api_config.dart` file
- ✅ Show you the new IP address

## 🛠️ Manual Update

If you prefer to update manually:

### 1. Find Your Current IP
```powershell
ipconfig | Select-String "IPv4"
```

Look for the IP address that looks like `10.x.x.x` or `192.168.x.x`

### 2. Update Backend (.env)
Edit `backend\.env`:
```env
LOCAL_IP=YOUR_NEW_IP_HERE
```

### 3. Update Flutter (api_config.dart)
Edit `lib\config\api_config.dart`:
```dart
const String localIp = 'YOUR_NEW_IP_HERE';
```

## 📱 Testing Different Devices

### Emulator (Android Studio/VS Code)
```dart
static const bool _useEmulator = true;  // Uses 10.0.2.2
```

### Physical Device (Phone/Tablet)
```dart
static const bool _useEmulator = false;  // Uses your local IP
```

**Important**: Your phone and computer must be on the **same WiFi network**!

## 🔍 Troubleshooting

### App can't connect to backend?

1. **Check if backend is running**:
   ```powershell
   cd backend
   python app.py
   ```
   You should see: `Running on http://YOUR_IP:5000`

2. **Check your IP hasn't changed**:
   ```powershell
   ipconfig | Select-String "IPv4"
   ```
   If it's different, run `.\update_ip.ps1`

3. **Check same network**:
   - Phone and computer must be on the same WiFi
   - Some networks block device-to-device communication

4. **Check firewall**:
   - Windows Firewall might block connections
   - Allow Python through firewall when prompted

### Backend starts but model doesn't load?

Make sure these files exist:
- `backend\models\food_model.h5` (177.7 MB)
- `backend\models\labels.txt`

## 🚀 Quick Start Guide

### First Time Setup
1. Run `.\update_ip.ps1` to configure IPs
2. Start backend: `cd backend; python app.py`
3. Start Flutter: `flutter run`

### After Changing WiFi Networks
1. Run `.\update_ip.ps1` to update IPs
2. Restart backend server
3. Hot reload Flutter app (press 'r' in terminal)

### Using Emulator
1. Set `_useEmulator = true` in `api_config.dart`
2. Hot reload Flutter app

### Using Physical Device
1. Set `_useEmulator = false` in `api_config.dart`
2. Run `.\update_ip.ps1` if IP changed
3. Hot reload Flutter app

## 📝 Configuration Files

### backend\.env
```env
# MongoDB Configuration
MONGODB_URI=mongodb+srv://...
DATABASE_NAME=crumbchain

# JWT Secret Key
JWT_SECRET_KEY=your-secret-key

# Server Configuration
PORT=5000
HOST=0.0.0.0
LOCAL_IP=10.9.31.173  ← Your local IP

# Upload Configuration
UPLOAD_FOLDER=uploads
MAX_FILE_SIZE=5242880

# Gemini AI Configuration
GEMINI_API_KEY=AIzaSy...
```

### lib\config\api_config.dart
```dart
class ApiConfig {
  static const bool _useEmulator = false;  ← Change for emulator
  
  static String get baseUrl {
    if (Platform.isAndroid) {
      const String localIp = '10.9.31.173';  ← Your local IP
      const String emulatorIp = '10.0.2.2';
      
      final ip = _useEmulator ? emulatorIp : localIp;
      return 'http://$ip:5000/api';
    }
    return 'http://localhost:5000/api';
  }
}
```

## 🎯 Summary

- ✅ IP stored in `.env` file for backend
- ✅ IP stored in `api_config.dart` for Flutter
- ✅ Automatic update script: `update_ip.ps1`
- ✅ Supports both emulator and physical devices
- ✅ Easy switching between configurations

**Current IP**: `10.9.31.173`
