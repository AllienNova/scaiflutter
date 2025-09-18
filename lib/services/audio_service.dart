import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:record/record.dart';
import 'package:audio_session/audio_session.dart';
import 'package:path_provider/path_provider.dart';
import 'package:logger/logger.dart';

import '../core/constants.dart';
import '../services/thehive_api_service.dart';
import '../services/call_recording_service.dart';
import '../models/call_model.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  static AudioService get instance => _instance;
  AudioService._internal();
  
  final Logger _logger = Logger();
  final AudioRecorder _recorder = AudioRecorder();
  
  bool _isRecording = false;
  bool _isInitialized = false;
  String? _currentRecordingPath;
  Timer? _chunkTimer;
  
  final StreamController<String> _audioChunkController = 
      StreamController<String>.broadcast();
  Stream<String> get audioChunkStream => _audioChunkController.stream;
  
  final StreamController<List<AnalysisResult>> _analysisController = 
      StreamController<List<AnalysisResult>>.broadcast();
  Stream<List<AnalysisResult>> get analysisStream => _analysisController.stream;
  
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      _logger.i('Initializing AudioService...');
      
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.speech());
      
      _isInitialized = true;
      _logger.i('AudioService initialized successfully');
    } catch (e) {
      _logger.e('Failed to initialize AudioService: $e');
      rethrow;
    }
  }
  
  Future<bool> startRecording(String callId) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    if (_isRecording) {
      _logger.w('Recording already in progress');
      return false;
    }
    
    try {
      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) {
        _logger.e('Microphone permission not granted');
        return false;
      }
      
      final directory = await getApplicationDocumentsDirectory();
      final recordingsDir = Directory('${directory.path}/recordings');
      if (!await recordingsDir.exists()) {
        await recordingsDir.create(recursive: true);
      }
      
      _currentRecordingPath = '${recordingsDir.path}/call_${callId}_${DateTime.now().millisecondsSinceEpoch}.wav';
      
      const config = RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: AppConstants.audioSampleRate,
        bitRate: AppConstants.audioBitRate,
        numChannels: 1,
      );
      
      await _recorder.start(config, path: _currentRecordingPath!);
      _isRecording = true;
      
      _startChunkProcessing(callId);
      
      _logger.i('Recording started: $_currentRecordingPath');
      return true;
    } catch (e) {
      _logger.e('Error starting recording: $e');
      return false;
    }
  }
  
  void _startChunkProcessing(String callId) {
    _chunkTimer = Timer.periodic(
      const Duration(seconds: AppConstants.audioChunkDurationSeconds),
      (timer) async {
        if (!_isRecording) {
          timer.cancel();
          return;
        }
        
        await _processAudioChunk(callId);
      },
    );
  }
  
  Future<void> _processAudioChunk(String callId) async {
    try {
      if (!_isRecording || _currentRecordingPath == null) return;
      
      final recordingFile = File(_currentRecordingPath!);
      if (!await recordingFile.exists()) return;
      
      final audioBytes = await recordingFile.readAsBytes();
      if (audioBytes.isEmpty) return;
      
      final chunkPath = await _createAudioChunk(audioBytes, callId);
      _audioChunkController.add(chunkPath);
      
      final analysisResults = await TheHiveApiService.instance.analyzeAudioChunk(chunkPath);
      _analysisController.add(analysisResults);
      
      _logger.i('Processed audio chunk: $chunkPath');
    } catch (e) {
      _logger.e('Error processing audio chunk: $e');
    }
  }
  
  Future<String> _createAudioChunk(Uint8List audioBytes, String callId) async {
    final directory = await getApplicationDocumentsDirectory();
    final chunksDir = Directory('${directory.path}/chunks');
    if (!await chunksDir.exists()) {
      await chunksDir.create(recursive: true);
    }
    
    final chunkPath = '${chunksDir.path}/chunk_${callId}_${DateTime.now().millisecondsSinceEpoch}.wav';
    final chunkFile = File(chunkPath);
    
    final maxChunkSize = (AppConstants.audioSampleRate * 
                         AppConstants.audioChunkDurationSeconds * 
                         2).clamp(0, audioBytes.length);
    
    final chunkBytes = audioBytes.sublist(
      (audioBytes.length - maxChunkSize).clamp(0, audioBytes.length),
      audioBytes.length,
    );
    
    await chunkFile.writeAsBytes(chunkBytes);
    return chunkPath;
  }
  
  Future<String?> stopRecording() async {
    if (!_isRecording) {
      _logger.w('No recording in progress');
      return null;
    }
    
    try {
      _chunkTimer?.cancel();
      _chunkTimer = null;
      
      final path = await _recorder.stop();
      _isRecording = false;
      
      if (path != null) {
        _logger.i('Recording stopped: $path');
        return path;
      } else {
        _logger.w('Recording stopped but no file path returned');
        return _currentRecordingPath;
      }
    } catch (e) {
      _logger.e('Error stopping recording: $e');
      return null;
    } finally {
      _currentRecordingPath = null;
    }
  }
  
  Future<void> pauseRecording() async {
    if (!_isRecording) return;
    
    try {
      await _recorder.pause();
      _chunkTimer?.cancel();
      _logger.i('Recording paused');
    } catch (e) {
      _logger.e('Error pausing recording: $e');
    }
  }
  
  Future<void> resumeRecording(String callId) async {
    if (!_isRecording) return;
    
    try {
      await _recorder.resume();
      _startChunkProcessing(callId);
      _logger.i('Recording resumed');
    } catch (e) {
      _logger.e('Error resuming recording: $e');
    }
  }
  
  Future<bool> isRecordingAsync() async {
    return await _recorder.isRecording();
  }
  
  Future<void> cleanupOldFiles() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final chunksDir = Directory('${directory.path}/chunks');
      
      if (await chunksDir.exists()) {
        final files = await chunksDir.list().toList();
        final cutoffTime = DateTime.now().subtract(const Duration(hours: 24));
        
        for (final file in files) {
          if (file is File) {
            final stat = await file.stat();
            if (stat.modified.isBefore(cutoffTime)) {
              await file.delete();
              _logger.i('Deleted old chunk file: ${file.path}');
            }
          }
        }
      }
    } catch (e) {
      _logger.e('Error cleaning up old files: $e');
    }
  }
  
  bool get isRecording => _isRecording;
  String? get currentRecordingPath => _currentRecordingPath;
  
  // Integration with call recording service
  Future<void> startCallRecording(String phoneNumber, bool isIncoming) async {
    try {
      _logger.i('Starting call recording for $phoneNumber (${isIncoming ? 'incoming' : 'outgoing'})');
      await CallRecordingService.instance.startRecording(phoneNumber, isIncoming);
    } catch (error) {
      _logger.e('Error starting call recording: $error');
    }
  }

  Future<void> stopCallRecording() async {
    try {
      _logger.i('Stopping call recording');
      final recording = await CallRecordingService.instance.stopRecording();
      if (recording != null) {
        _logger.i('Call recording saved: ${recording.fileName}');
      }
    } catch (error) {
      _logger.e('Error stopping call recording: $error');
    }
  }

  bool get isCallRecording => CallRecordingService.instance.isRecording;

  void dispose() {
    _chunkTimer?.cancel();
    _recorder.dispose();
    _audioChunkController.close();
    _analysisController.close();
    _isRecording = false;
    _isInitialized = false;
  }
}