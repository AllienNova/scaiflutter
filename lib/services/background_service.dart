import 'dart:async';
import 'package:workmanager/workmanager.dart';
import 'package:logger/logger.dart';

import '../services/call_service.dart';
import '../services/audio_service.dart';
import '../services/thehive_api_service.dart';
import '../services/database_service.dart';

class BackgroundService {
  static final BackgroundService _instance = BackgroundService._internal();
  static BackgroundService get instance => _instance;
  BackgroundService._internal();
  
  final Logger _logger = Logger();
  
  Future<void> initialize() async {
    try {
      _logger.i('Initializing background service...');
      
      await Workmanager().registerPeriodicTask(
        'callMonitoring',
        'callMonitoring',
        frequency: const Duration(seconds: 30),
        constraints: Constraints(
          networkType: NetworkType.connected,
          requiresBatteryNotLow: false,
          requiresCharging: false,
          requiresDeviceIdle: false,
        ),
      );
      
      _logger.i('Background service initialized');
    } catch (e) {
      _logger.e('Error initializing background service: $e');
    }
  }
  
  Future<void> monitorCalls() async {
    try {
      _logger.d('Monitoring calls...');
      
      if (CallService.instance.isCallActive) {
        final currentCall = CallService.instance.currentCall;
        if (currentCall != null) {
          await _processActiveCall(currentCall.id);
        }
      }
    } catch (e) {
      _logger.e('Error monitoring calls: $e');
    }
  }
  
  Future<void> _processActiveCall(String callId) async {
    try {
      if (!AudioService.instance.isRecording) {
        await AudioService.instance.startRecording(callId);
      }
      
      _logger.d('Processing active call: $callId');
    } catch (e) {
      _logger.e('Error processing active call: $e');
    }
  }
  
  Future<void> processAudioChunk(String? audioPath) async {
    if (audioPath == null) return;
    
    try {
      _logger.d('Processing audio chunk: $audioPath');
      
      final analysisResults = await TheHiveApiService.instance.analyzeAudioChunk(audioPath);
      
      for (final result in analysisResults) {
        await DatabaseService.instance.insertAnalysisResult(result);
      }
      
      if (analysisResults.any((r) => r.isScamIndicator)) {
        await _handleScamDetection(analysisResults);
      }
    } catch (e) {
      _logger.e('Error processing audio chunk: $e');
    }
  }
  
  Future<void> _handleScamDetection(List<dynamic> analysisResults) async {
    try {
      _logger.w('Scam detected in audio analysis');
      
      // This would trigger notifications, alerts, etc.
      // Implementation depends on specific requirements
    } catch (e) {
      _logger.e('Error handling scam detection: $e');
    }
  }
  
  Future<void> scheduleAudioProcessing(String audioPath) async {
    try {
      await Workmanager().registerOneOffTask(
        'audioProcessing_${DateTime.now().millisecondsSinceEpoch}',
        'audioProcessing',
        inputData: {'audioPath': audioPath},
        constraints: Constraints(
          networkType: NetworkType.connected,
        ),
      );
    } catch (e) {
      _logger.e('Error scheduling audio processing: $e');
    }
  }
  
  Future<void> cleanup() async {
    try {
      await AudioService.instance.cleanupOldFiles();
      _logger.i('Background cleanup completed');
    } catch (e) {
      _logger.e('Error during cleanup: $e');
    }
  }
  
  Future<void> stop() async {
    try {
      await Workmanager().cancelAll();
      _logger.i('Background service stopped');
    } catch (e) {
      _logger.e('Error stopping background service: $e');
    }
  }
}