import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../models/call_recording_model.dart';
import '../services/call_recording_service.dart';
import '../services/backend_api_service.dart';

final callRecordingProvider = StateNotifierProvider<CallRecordingNotifier, AsyncValue<List<CallRecording>>>((ref) {
  return CallRecordingNotifier(ref);
});

class CallRecordingNotifier extends StateNotifier<AsyncValue<List<CallRecording>>> {
  CallRecordingNotifier(this.ref) : super(const AsyncValue.loading()) {
    loadRecordings();
  }

  final Ref ref;
  final Logger _logger = Logger();

  Future<void> loadRecordings() async {
    try {
      state = const AsyncValue.loading();
      final recordings = await CallRecordingService.instance.getAllRecordings();
      state = AsyncValue.data(recordings);
      _logger.i('Loaded ${recordings.length} call recordings');
    } catch (error, stackTrace) {
      _logger.e('Error loading recordings: $error');
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> addRecording(CallRecording recording) async {
    try {
      await CallRecordingService.instance.saveRecording(recording);
      await loadRecordings(); // Refresh the list
      _logger.i('Added new recording: ${recording.id}');
    } catch (error) {
      _logger.e('Error adding recording: $error');
    }
  }

  Future<void> deleteRecording(String recordingId) async {
    try {
      await CallRecordingService.instance.deleteRecording(recordingId);
      await loadRecordings(); // Refresh the list
      _logger.i('Deleted recording: $recordingId');
    } catch (error) {
      _logger.e('Error deleting recording: $error');
    }
  }

  Future<void> analyzeRecording(String recordingId) async {
    try {
      // Update state to show analyzing
      state.whenData((recordings) {
        final updatedRecordings = recordings.map((recording) {
          if (recording.id == recordingId) {
            return recording.copyWith(isAnalyzing: true);
          }
          return recording;
        }).toList();
        state = AsyncValue.data(updatedRecordings);
      });

      // Get the recording
      final recording = await CallRecordingService.instance.getRecording(recordingId);
      if (recording == null) {
        throw Exception('Recording not found');
      }

      // Send to backend for analysis
      final analysisResult = await BackendApiService.instance.analyzeAudio(
        recording.filePath,
        phoneNumber: recording.phoneNumber,
        callType: recording.callTypeText,
        callDuration: recording.duration.inSeconds,
        timestamp: recording.timestamp.toIso8601String(),
      );

      // Update recording with analysis result
      final updatedRecording = recording.copyWith(
        analysisResult: analysisResult,
        isAnalyzing: false,
      );

      await CallRecordingService.instance.updateRecording(updatedRecording);
      await loadRecordings(); // Refresh the list

      _logger.i('Analysis completed for recording: $recordingId');
    } catch (error) {
      _logger.e('Error analyzing recording: $error');
      
      // Update state to remove analyzing status
      state.whenData((recordings) {
        final updatedRecordings = recordings.map((recording) {
          if (recording.id == recordingId) {
            return recording.copyWith(isAnalyzing: false);
          }
          return recording;
        }).toList();
        state = AsyncValue.data(updatedRecordings);
      });
    }
  }

  Future<void> startRecording(String phoneNumber, bool isIncoming) async {
    try {
      await CallRecordingService.instance.startRecording(phoneNumber, isIncoming);
      _logger.i('Started recording for $phoneNumber');
    } catch (error) {
      _logger.e('Error starting recording: $error');
    }
  }

  Future<void> stopRecording() async {
    try {
      final recording = await CallRecordingService.instance.stopRecording();
      if (recording != null) {
        await loadRecordings(); // Refresh the list
        _logger.i('Stopped recording: ${recording.id}');
      }
    } catch (error) {
      _logger.e('Error stopping recording: $error');
    }
  }
}
