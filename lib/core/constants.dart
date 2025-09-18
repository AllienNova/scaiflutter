class AppConstants {
  static const String appName = 'ScamShieldAI';
  static const String appVersion = '1.0.0';
  
  static const String theHiveApiBaseUrl = 'https://api.thehive.ai/v1';
  static const String theHiveApiKey = 'YOUR_API_KEY_HERE';
  
  static const int audioChunkDurationSeconds = 10;
  static const int audioSampleRate = 44100;
  static const int audioBitRate = 128000;
  
  static const double animationDuration = 0.3;
  static const double fastAnimationDuration = 0.15;
  static const double slowAnimationDuration = 0.6;
  
  static const String dbName = 'scai_database.db';
  static const int dbVersion = 1;
  
  static const String prefsKeyThemeMode = 'theme_mode';
  static const String prefsKeyAnalysisSensitivity = 'analysis_sensitivity';
  static const String prefsKeyNotificationsEnabled = 'notifications_enabled';
  static const String prefsKeyAutoRecording = 'auto_recording';
  
  static const List<String> supportedAudioFormats = ['wav', 'mp3', 'aac'];
  
  static const Map<String, String> scamIndicators = {
    'urgent_payment': 'Urgent payment request detected',
    'personal_info': 'Personal information request detected',
    'bank_details': 'Banking details request detected',
    'deepfake': 'Potential voice deepfake detected',
    'high_stress': 'High stress/pressure tactics detected',
  };
}

class ApiEndpoints {
  static const String deepfakeDetection = '/audio/deepfake-detect';
  static const String sentimentAnalysis = '/audio/sentiment-analysis';
  static const String voiceAuthentication = '/audio/voice-auth';
  static const String scamPatternDetection = '/audio/scam-patterns';
}

class DatabaseTables {
  static const String calls = 'calls';
  static const String recordings = 'recordings';
  static const String analysisResults = 'analysis_results';
  static const String contacts = 'contacts';
  static const String scamReports = 'scam_reports';
}

class NotificationChannels {
  static const String scamAlert = 'scam_alert';
  static const String callRecording = 'call_recording';
  static const String systemUpdates = 'system_updates';
}