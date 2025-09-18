# SCAI Guard - AI-Powered Call Protection

A comprehensive Flutter application that provides real-time scam detection and anti-fraud capabilities for phone calls using advanced AI analysis.

## 🚀 Features

### Core Functionality
- **Default Phone/SMS App**: Functions as the primary dialer and messaging app for Android devices
- **Real-Time Call Recording**: Automatically records voice calls during active conversations
- **AI-Powered Analysis**: Streams audio in 10-second intervals to TheHive.ai API for analysis
- **Deepfake Detection**: Identifies synthetic or manipulated voice patterns
- **Sentiment Analysis**: Analyzes emotional context and stress indicators
- **Live Scam Alerts**: Displays real-time warnings during suspicious calls
- **Background Monitoring**: Continuous protection even when app is not active

### AI Analysis Capabilities
- **Voice Authentication**: Verifies voice authenticity
- **Deepfake Detection**: Identifies artificially generated voices
- **Sentiment Analysis**: Detects high-pressure tactics and emotional manipulation
- **Scam Pattern Recognition**: Identifies common fraud keywords and phrases
- **Stress Level Analysis**: Monitors caller stress indicators

### User Interface
- **Cinematic Animations**: Smooth transitions and micro-interactions
- **Real-Time Visual Indicators**: Live analysis display during calls
- **Intuitive Call Interface**: Professional and user-friendly design
- **Customizable Settings**: Adjustable sensitivity and notification preferences
- **Accessibility Compliant**: Responsive design with accessibility features

## 🛠️ Technical Requirements

### Dependencies
- Flutter 3.10.0+
- Dart 3.0.0+
- Android SDK 21+ (Android 5.0)
- TheHive.ai API access

### Key Packages
- `flutter_riverpod`: State management
- `record`: Audio recording capabilities
- `phone_state`: Call state monitoring
- `permission_handler`: Permission management
- `flutter_animate`: Animation framework
- `workmanager`: Background processing
- `sqflite`: Local database storage
- `dio`: HTTP client for API calls

## 📱 Installation & Setup

### 1. Clone the Repository
```bash
git clone https://github.com/your-username/scai-guard.git
cd scai-guard
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Configure API Keys
Update `lib/core/constants.dart` with your TheHive.ai API credentials:
```dart
static const String theHiveApiKey = 'YOUR_API_KEY_HERE';
```

### 4. Generate Code
```bash
dart run build_runner build
```

### 5. Run the Application
```bash
flutter run
```

## 🔧 Configuration

### Android Permissions
The app requires several sensitive permissions to function properly:

- **Phone Access**: Read phone state, make calls, access call logs
- **Microphone**: Record audio during calls
- **Storage**: Save call recordings and analysis data
- **Contacts**: Identify callers
- **SMS**: Analyze text messages for scam patterns
- **System Overlay**: Display scam alerts during calls
- **Background**: Continuous monitoring capabilities

### TheHive.ai API Setup
1. Sign up for TheHive.ai API access
2. Obtain your API key and endpoints
3. Update the configuration in `constants.dart`
4. Test the connection using the built-in diagnostics

## 🏗️ Architecture

### Project Structure
```
lib/
├── core/                 # Core utilities and constants
├── models/               # Data models
├── providers/            # State management
├── screens/              # UI screens
├── services/             # Business logic and API services
├── widgets/              # Reusable UI components
└── main.dart            # Application entry point
```

### Key Services
- **CallService**: Manages phone call functionality and monitoring
- **AudioService**: Handles real-time audio recording and streaming
- **TheHiveApiService**: Integrates with AI analysis APIs
- **PermissionService**: Manages app permissions
- **DatabaseService**: Local data storage and retrieval
- **BackgroundService**: Background processing and monitoring

## 🔒 Privacy & Security

### Data Protection
- **Local Processing**: Audio analysis happens in real-time
- **Encrypted Transmission**: All API communications use HTTPS
- **Minimal Storage**: Only essential data is stored locally
- **User Control**: Complete control over data retention and deletion

### Privacy Features
- **Opt-in Recording**: Users can disable automatic recording
- **Data Encryption**: Local storage is encrypted
- **Automatic Cleanup**: Old recordings are automatically deleted
- **Privacy Settings**: Granular control over data sharing

## 🎨 UI/UX Design

### Design Principles
- **Material Design 3**: Modern, consistent design language
- **Accessibility First**: Screen reader support and high contrast options
- **Responsive Layout**: Optimized for various screen sizes
- **Intuitive Navigation**: Clear user flows and interactions

### Animation Framework
- **Flutter Animate**: Smooth, performant animations
- **Micro-interactions**: Feedback for user actions
- **Loading States**: Clear progress indicators
- **Error Handling**: User-friendly error messages

## 🚨 Usage Guidelines

### Setting as Default Phone App
1. Open Settings → Apps → Default Apps
2. Select "Phone app"
3. Choose "SCAI Guard"
4. Grant all required permissions

### Monitoring Calls
1. Make or receive a call
2. The app automatically starts recording and analysis
3. Watch for real-time scam indicators
4. Follow on-screen alerts if suspicious activity is detected

### Managing Settings
- Adjust analysis sensitivity in Settings
- Enable/disable notifications
- Configure recording preferences
- Manage blocked numbers

## 🔧 Development

### Building for Release
```bash
flutter build apk --release
```

### Testing
```bash
flutter test
```

### Debugging
```bash
flutter run --debug
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

### Getting Help
- Check the [Issues](https://github.com/your-username/scai-guard/issues) page
- Review the [Documentation](docs/)
- Contact support through the app settings

### Known Issues
- Some Android devices may require additional permissions
- Background monitoring may be limited by battery optimization settings
- TheHive.ai API rate limits may affect real-time processing

## 🔮 Roadmap

### Upcoming Features
- **iOS Support**: Native iOS implementation
- **Call Blocking**: Automatic blocking of known scam numbers
- **Community Database**: Shared scam number database
- **Advanced Analytics**: Detailed call analysis reports
- **Multi-language Support**: Localization for global users

### Version History
- **v1.0.0**: Initial release with core scam detection features
- **v1.1.0**: Enhanced UI/UX and additional analysis types
- **v1.2.0**: Background service improvements and battery optimization

## 💡 Technical Notes

### Performance Optimization
- Efficient audio streaming in 10-second chunks
- Background processing with WorkManager
- SQLite database with optimized queries
- Memory management for large audio files

### Battery Usage
- Optimized background service
- Configurable monitoring intervals
- Battery usage statistics and controls
- Power-saving mode compatibility

### Error Handling
- Comprehensive error logging
- Graceful fallbacks for network issues
- User-friendly error messages
- Automatic retry mechanisms

---

**SCAI Guard** - Protecting you from scam calls with the power of AI. Stay safe, stay informed.