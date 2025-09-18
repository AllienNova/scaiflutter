import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

import '../models/call_recording_model.dart';

class CallRecordingService {
  static final CallRecordingService _instance = CallRecordingService._internal();
  static CallRecordingService get instance => _instance;
  CallRecordingService._internal();

  final Logger _logger = Logger();
  final AudioRecorder _recorder = AudioRecorder();
  final Uuid _uuid = const Uuid();

  CallRecording? _currentRecording;
  DateTime? _recordingStartTime;

  // Storage paths
  late Directory _recordingsDirectory;
  late File _recordingsIndexFile;

  Future<void> initialize() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      _recordingsDirectory = Directory('${appDir.path}/call_recordings');
      
      if (!await _recordingsDirectory.exists()) {
        await _recordingsDirectory.create(recursive: true);
      }

      _recordingsIndexFile = File('${_recordingsDirectory.path}/recordings_index.json');
      
      _logger.i('Call recording service initialized');
      _logger.i('Recordings directory: ${_recordingsDirectory.path}');
    } catch (error) {
      _logger.e('Error initializing call recording service: $error');
    }
  }

  Future<void> startRecording(String phoneNumber, bool isIncoming) async {
    try {
      if (_currentRecording != null) {
        _logger.w('Recording already in progress, stopping previous recording');
        await stopRecording();
      }

      // Check microphone permission
      if (!await _recorder.hasPermission()) {
        throw Exception('Microphone permission not granted');
      }

      final recordingId = _uuid.v4();
      final timestamp = DateTime.now();
      final fileName = _generateFileName(phoneNumber, isIncoming, timestamp);
      final filePath = '${_recordingsDirectory.path}/$fileName';

      // Start recording (microphone only - system app required for full call recording)
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: filePath,
      );

      _recordingStartTime = timestamp;
      _currentRecording = CallRecording(
        id: recordingId,
        phoneNumber: phoneNumber,
        isIncoming: isIncoming,
        timestamp: timestamp,
        duration: Duration.zero,
        fileName: fileName,
        filePath: filePath,
        fileSize: 0,
      );

      _logger.i('Started recording: $fileName');
      _logger.w('Recording microphone only - install as system app for full call recording');
    } catch (error) {
      _logger.e('Error starting recording: $error');
      _currentRecording = null;
      _recordingStartTime = null;
      rethrow;
    }
  }

  Future<CallRecording?> stopRecording() async {
    try {
      if (_currentRecording == null || _recordingStartTime == null) {
        _logger.w('No recording in progress');
        return null;
      }

      // Stop recording
      final recordingPath = await _recorder.stop();
      if (recordingPath == null) {
        throw Exception('Failed to stop recording');
      }

      // Calculate duration and file size
      final duration = DateTime.now().difference(_recordingStartTime!);
      final file = File(recordingPath);
      final fileSize = await file.length();

      // Update recording with final details
      final finalRecording = _currentRecording!.copyWith(
        duration: duration,
        fileSize: fileSize,
      );

      // Save to index
      await saveRecording(finalRecording);

      _logger.i('Stopped recording: ${finalRecording.fileName}');
      _logger.i('Duration: ${finalRecording.formattedDuration}');
      _logger.i('File size: ${finalRecording.formattedFileSize}');

      final result = finalRecording;
      _currentRecording = null;
      _recordingStartTime = null;

      return result;
    } catch (error) {
      _logger.e('Error stopping recording: $error');
      _currentRecording = null;
      _recordingStartTime = null;
      rethrow;
    }
  }

  Future<void> saveRecording(CallRecording recording) async {
    try {
      final recordings = await getAllRecordings();
      recordings.add(recording);
      await _saveRecordingsIndex(recordings);
      _logger.i('Saved recording to index: ${recording.id}');
    } catch (error) {
      _logger.e('Error saving recording: $error');
      rethrow;
    }
  }

  Future<void> updateRecording(CallRecording recording) async {
    try {
      final recordings = await getAllRecordings();
      final index = recordings.indexWhere((r) => r.id == recording.id);
      
      if (index != -1) {
        recordings[index] = recording;
        await _saveRecordingsIndex(recordings);
        _logger.i('Updated recording: ${recording.id}');
      } else {
        throw Exception('Recording not found: ${recording.id}');
      }
    } catch (error) {
      _logger.e('Error updating recording: $error');
      rethrow;
    }
  }

  Future<void> deleteRecording(String recordingId) async {
    try {
      final recordings = await getAllRecordings();
      final recording = recordings.firstWhere((r) => r.id == recordingId);
      
      // Delete file
      final file = File(recording.filePath);
      if (await file.exists()) {
        await file.delete();
      }

      // Remove from index
      recordings.removeWhere((r) => r.id == recordingId);
      await _saveRecordingsIndex(recordings);

      _logger.i('Deleted recording: $recordingId');
    } catch (error) {
      _logger.e('Error deleting recording: $error');
      rethrow;
    }
  }

  Future<CallRecording?> getRecording(String recordingId) async {
    try {
      final recordings = await getAllRecordings();
      return recordings.firstWhere((r) => r.id == recordingId);
    } catch (error) {
      _logger.e('Error getting recording: $error');
      return null;
    }
  }

  Future<List<CallRecording>> getAllRecordings() async {
    try {
      if (!await _recordingsIndexFile.exists()) {
        return [];
      }

      final content = await _recordingsIndexFile.readAsString();
      final List<dynamic> jsonList = json.decode(content);
      
      return jsonList.map((json) => CallRecording.fromJson(json)).toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp)); // Most recent first
    } catch (error) {
      _logger.e('Error loading recordings: $error');
      return [];
    }
  }

  Future<void> _saveRecordingsIndex(List<CallRecording> recordings) async {
    try {
      final jsonList = recordings.map((r) => r.toJson()).toList();
      final content = json.encode(jsonList);
      await _recordingsIndexFile.writeAsString(content);
    } catch (error) {
      _logger.e('Error saving recordings index: $error');
      rethrow;
    }
  }

  String _generateFileName(String phoneNumber, bool isIncoming, DateTime timestamp) {
    final dateFormat = DateFormat('yyyyMMdd_HHmmss');
    final formattedDate = dateFormat.format(timestamp);
    final callType = isIncoming ? 'incoming' : 'outgoing';
    final sanitizedNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    
    return 'call_${callType}_${sanitizedNumber}_$formattedDate.aac';
  }



  bool get isRecording => _currentRecording != null;

  CallRecording? get currentRecording => _currentRecording;

  /// Check if app has system-level call recording capabilities
  Future<bool> hasSystemCallRecordingCapability() async {
    try {
      // This would require a platform channel to check if app is system app
      // For now, return false as most installations are user apps
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Get recording capability status message
  String getRecordingCapabilityMessage() {
    return 'Recording microphone audio only. For full call recording (both sides), '
           'install SCAI as a system app. See SYSTEM_APP_INSTALLATION_GUIDE.md for details.';
  }
}
