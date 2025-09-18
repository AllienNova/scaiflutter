import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'dart:async';

import '../models/call_recording_model.dart';
import 'call_recording_service.dart';
import 'backend_api_service.dart';
import 'phone_state_platform_service.dart';

enum RecordingMode {
  manual,      // User manually starts/stops recording
  demo,        // Simulated calls with sample data
  automatic,   // Real phone call detection (when available)
}

enum DemoScenario {
  legitimateCall,
  robocall,
  phishingScam,
  techSupportScam,
  irsScam,
}

class RecordingModeService {
  static final RecordingModeService _instance = RecordingModeService._internal();
  static RecordingModeService get instance => _instance;
  RecordingModeService._internal();

  final Logger _logger = Logger();
  
  RecordingMode _currentMode = RecordingMode.manual;
  bool _isDemoRunning = false;
  Timer? _demoTimer;

  RecordingMode get currentMode => _currentMode;
  bool get isDemoRunning => _isDemoRunning;

  final StreamController<RecordingMode> _modeController = 
      StreamController<RecordingMode>.broadcast();
  Stream<RecordingMode> get modeStream => _modeController.stream;

  final StreamController<String> _statusController = 
      StreamController<String>.broadcast();
  Stream<String> get statusStream => _statusController.stream;

  Future<void> setMode(RecordingMode mode) async {
    _logger.i('Switching recording mode to: $mode');

    // Handle mode-specific setup
    try {
      switch (mode) {
        case RecordingMode.automatic:
          await enableAutomaticMode();
          break;
        case RecordingMode.manual:
        case RecordingMode.demo:
          // Disable automatic mode if it was previously enabled
          if (_currentMode == RecordingMode.automatic) {
            await disableAutomaticMode();
          }
          break;
      }

      _currentMode = mode;
      _modeController.add(mode);

      if (mode != RecordingMode.demo && _isDemoRunning) {
        stopDemo();
      }

    } catch (error) {
      _logger.e('Error switching to mode $mode: $error');
      _statusController.add('Error switching mode: $error');
      rethrow;
    }
  }

  // Manual Recording Methods
  Future<void> startManualRecording({
    String? phoneNumber,
    String? contactName,
    bool isIncoming = false,
  }) async {
    if (_currentMode != RecordingMode.manual) {
      throw Exception('Not in manual recording mode');
    }

    try {
      _logger.i('Starting manual recording');
      _statusController.add('Starting manual recording...');
      
      final number = phoneNumber ?? 'Manual Recording';
      await CallRecordingService.instance.startRecording(number, isIncoming);
      
      _statusController.add('Recording in progress...');
    } catch (error) {
      _logger.e('Error starting manual recording: $error');
      _statusController.add('Error: $error');
      rethrow;
    }
  }

  Future<CallRecording?> stopManualRecording() async {
    if (_currentMode != RecordingMode.manual) {
      throw Exception('Not in manual recording mode');
    }

    try {
      _logger.i('Stopping manual recording');
      _statusController.add('Stopping recording...');
      
      final recording = await CallRecordingService.instance.stopRecording();
      
      if (recording != null) {
        _statusController.add('Recording saved: ${recording.fileName}');
      } else {
        _statusController.add('No recording to save');
      }
      
      return recording;
    } catch (error) {
      _logger.e('Error stopping manual recording: $error');
      _statusController.add('Error: $error');
      rethrow;
    }
  }

  // Demo Mode Methods
  Future<void> startDemo(DemoScenario scenario) async {
    if (_currentMode != RecordingMode.demo) {
      throw Exception('Not in demo mode');
    }

    if (_isDemoRunning) {
      await stopDemo();
    }

    try {
      _logger.i('Starting demo scenario: $scenario');
      _isDemoRunning = true;
      _statusController.add('Starting demo: ${_getScenarioName(scenario)}');

      final demoData = _getDemoData(scenario);
      
      // Simulate incoming call
      _statusController.add('Incoming call from ${demoData['phoneNumber']}...');
      await Future.delayed(const Duration(seconds: 2));

      // Start recording
      await CallRecordingService.instance.startRecording(
        demoData['phoneNumber'],
        demoData['isIncoming'],
      );
      
      _statusController.add('Call connected - Recording started');
      
      // Simulate call duration
      final duration = demoData['duration'] as int;
      _demoTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        final elapsed = timer.tick;
        final remaining = duration - elapsed;
        
        if (remaining > 0) {
          _statusController.add('Recording... ${elapsed}s / ${duration}s');
        } else {
          _finishDemo(scenario);
        }
      });

    } catch (error) {
      _logger.e('Error starting demo: $error');
      _statusController.add('Demo error: $error');
      _isDemoRunning = false;
    }
  }

  Future<void> _finishDemo(DemoScenario scenario) async {
    try {
      _demoTimer?.cancel();
      _statusController.add('Call ended - Processing recording...');
      
      // Stop recording
      final recording = await CallRecordingService.instance.stopRecording();
      
      if (recording != null) {
        _statusController.add('Analyzing recording...');
        
        // Simulate analysis with predetermined results
        await Future.delayed(const Duration(seconds: 3));
        
        final mockAnalysis = _getMockAnalysis(scenario);
        final updatedRecording = recording.copyWith(
          analysisResult: mockAnalysis,
        );
        
        await CallRecordingService.instance.updateRecording(updatedRecording);
        
        _statusController.add(
          'Demo complete! ${mockAnalysis.isScam ? "⚠️ SCAM DETECTED" : "✅ Safe call"}'
        );
      }
      
    } catch (error) {
      _logger.e('Error finishing demo: $error');
      _statusController.add('Demo error: $error');
    } finally {
      _isDemoRunning = false;
    }
  }

  Future<void> stopDemo() async {
    if (!_isDemoRunning) return;

    try {
      _logger.i('Stopping demo');
      _demoTimer?.cancel();
      
      if (CallRecordingService.instance.isRecording) {
        await CallRecordingService.instance.stopRecording();
      }
      
      _statusController.add('Demo stopped');
    } catch (error) {
      _logger.e('Error stopping demo: $error');
    } finally {
      _isDemoRunning = false;
    }
  }

  // Real Phone Integration
  Future<void> enableAutomaticMode() async {
    try {
      _logger.i('Enabling automatic call recording mode');
      _statusController.add('Enabling automatic call recording...');

      // Check if phone state monitoring is active
      final isActive = await PhoneStatePlatformService.instance.isPhoneStateMonitoringActive();

      if (!isActive) {
        _statusController.add('Starting phone state monitoring...');
        await PhoneStatePlatformService.instance.startPhoneStateMonitoring();
      }

      _statusController.add('Automatic call recording enabled - monitoring phone state');
      _logger.i('Automatic mode enabled successfully');

    } catch (error) {
      _logger.e('Error enabling automatic mode: $error');
      _statusController.add('Error: $error');
      throw Exception('Failed to enable automatic mode: $error');
    }
  }

  Future<void> disableAutomaticMode() async {
    try {
      _logger.i('Disabling automatic call recording mode');
      _statusController.add('Disabling automatic call recording...');

      await PhoneStatePlatformService.instance.stopPhoneStateMonitoring();

      _statusController.add('Automatic call recording disabled');
      _logger.i('Automatic mode disabled successfully');

    } catch (error) {
      _logger.e('Error disabling automatic mode: $error');
      _statusController.add('Error: $error');
    }
  }

  // Helper Methods
  Map<String, dynamic> _getDemoData(DemoScenario scenario) {
    switch (scenario) {
      case DemoScenario.legitimateCall:
        return {
          'phoneNumber': '+1 (555) 123-4567',
          'contactName': 'John Smith',
          'isIncoming': true,
          'duration': 15, // seconds
        };
      case DemoScenario.robocall:
        return {
          'phoneNumber': '+1 (800) 555-0199',
          'contactName': null,
          'isIncoming': true,
          'duration': 12,
        };
      case DemoScenario.phishingScam:
        return {
          'phoneNumber': '+1 (555) 987-6543',
          'contactName': 'Bank Security',
          'isIncoming': true,
          'duration': 20,
        };
      case DemoScenario.techSupportScam:
        return {
          'phoneNumber': '+1 (888) 555-0123',
          'contactName': 'Microsoft Support',
          'isIncoming': true,
          'duration': 25,
        };
      case DemoScenario.irsScam:
        return {
          'phoneNumber': '+1 (202) 555-0100',
          'contactName': 'IRS Department',
          'isIncoming': true,
          'duration': 18,
        };
    }
  }

  AnalysisResult _getMockAnalysis(DemoScenario scenario) {
    final now = DateTime.now();
    
    switch (scenario) {
      case DemoScenario.legitimateCall:
        return AnalysisResult(
          id: 'demo_${now.millisecondsSinceEpoch}',
          confidenceScore: 15.0,
          scamType: 'LEGITIMATE',
          riskLevel: 'LOW',
          isScam: false,
          analysisTimestamp: now,
          keywords: ['normal', 'conversation', 'friendly'],
          flags: [],
        );
      case DemoScenario.robocall:
        return AnalysisResult(
          id: 'demo_${now.millisecondsSinceEpoch}',
          confidenceScore: 85.0,
          scamType: 'ROBOCALL',
          riskLevel: 'HIGH',
          isScam: true,
          analysisTimestamp: now,
          keywords: ['automated', 'press', 'number', 'offer'],
          flags: ['AUTOMATED_VOICE', 'SUSPICIOUS_KEYWORDS'],
        );
      case DemoScenario.phishingScam:
        return AnalysisResult(
          id: 'demo_${now.millisecondsSinceEpoch}',
          confidenceScore: 92.0,
          scamType: 'PHISHING',
          riskLevel: 'CRITICAL',
          isScam: true,
          analysisTimestamp: now,
          keywords: ['verify', 'account', 'suspended', 'urgent', 'security'],
          flags: ['PRESSURE_TACTICS', 'ACCOUNT_VERIFICATION', 'URGENCY'],
        );
      case DemoScenario.techSupportScam:
        return AnalysisResult(
          id: 'demo_${now.millisecondsSinceEpoch}',
          confidenceScore: 88.0,
          scamType: 'TECH_SUPPORT',
          riskLevel: 'HIGH',
          isScam: true,
          analysisTimestamp: now,
          keywords: ['computer', 'virus', 'infected', 'remote', 'access'],
          flags: ['TECH_SUPPORT_CLAIM', 'REMOTE_ACCESS_REQUEST'],
        );
      case DemoScenario.irsScam:
        return AnalysisResult(
          id: 'demo_${now.millisecondsSinceEpoch}',
          confidenceScore: 95.0,
          scamType: 'IRS_SCAM',
          riskLevel: 'CRITICAL',
          isScam: true,
          analysisTimestamp: now,
          keywords: ['irs', 'taxes', 'arrest', 'warrant', 'payment'],
          flags: ['GOVERNMENT_IMPERSONATION', 'THREAT_OF_ARREST', 'IMMEDIATE_PAYMENT'],
        );
    }
  }

  String _getScenarioName(DemoScenario scenario) {
    switch (scenario) {
      case DemoScenario.legitimateCall:
        return 'Legitimate Business Call';
      case DemoScenario.robocall:
        return 'Automated Robocall';
      case DemoScenario.phishingScam:
        return 'Banking Phishing Scam';
      case DemoScenario.techSupportScam:
        return 'Tech Support Scam';
      case DemoScenario.irsScam:
        return 'IRS Impersonation Scam';
    }
  }

  void dispose() {
    _demoTimer?.cancel();
    _modeController.close();
    _statusController.close();
  }
}
