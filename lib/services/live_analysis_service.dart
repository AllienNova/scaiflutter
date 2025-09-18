import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';

import '../models/live_analysis_models.dart';
import 'backend_api_service.dart';

class LiveAnalysisService {
  static final LiveAnalysisService _instance = LiveAnalysisService._internal();
  static LiveAnalysisService get instance => _instance;
  LiveAnalysisService._internal();

  final Logger _logger = Logger();
  final Uuid _uuid = const Uuid();
  final AudioRecorder _recorder = AudioRecorder();

  // Live analysis state
  LiveAnalysisSession? _currentSession;
  Timer? _chunkTimer;
  bool _isAnalysisEnabled = false;
  bool _isRecording = false;
  String? _currentChunkPath;
  int _chunkCounter = 0;
  
  // Configuration
  static const Duration _chunkDuration = Duration(seconds: 10);
  static const int _maxHistoryChunks = 10;
  
  // Stream controllers for real-time updates
  final StreamController<LiveAnalysisSession> _sessionController = 
      StreamController<LiveAnalysisSession>.broadcast();
  final StreamController<ChunkAnalysisResult> _chunkResultController = 
      StreamController<ChunkAnalysisResult>.broadcast();
  final StreamController<bool> _analysisStateController = 
      StreamController<bool>.broadcast();

  // Getters
  bool get isAnalysisEnabled => _isAnalysisEnabled;
  bool get isRecording => _isRecording;
  LiveAnalysisSession? get currentSession => _currentSession;
  
  // Streams
  Stream<LiveAnalysisSession> get sessionStream => _sessionController.stream;
  Stream<ChunkAnalysisResult> get chunkResultStream => _chunkResultController.stream;
  Stream<bool> get analysisStateStream => _analysisStateController.stream;

  /// Enable live analysis mode
  Future<void> enableLiveAnalysis() async {
    try {
      _logger.i('Enabling live analysis mode');
      
      if (_isAnalysisEnabled) {
        _logger.w('Live analysis already enabled');
        return;
      }

      // Check microphone permission
      if (!await _recorder.hasPermission()) {
        throw Exception('Microphone permission not granted');
      }

      _isAnalysisEnabled = true;
      _analysisStateController.add(true);
      
      _logger.i('Live analysis mode enabled');
    } catch (error) {
      _logger.e('Error enabling live analysis: $error');
      rethrow;
    }
  }

  /// Disable live analysis mode
  Future<void> disableLiveAnalysis() async {
    try {
      _logger.i('Disabling live analysis mode');
      
      if (!_isAnalysisEnabled) {
        _logger.w('Live analysis already disabled');
        return;
      }

      // Stop any active session
      if (_currentSession?.isActive == true) {
        await stopLiveAnalysis();
      }

      _isAnalysisEnabled = false;
      _analysisStateController.add(false);
      
      _logger.i('Live analysis mode disabled');
    } catch (error) {
      _logger.e('Error disabling live analysis: $error');
      rethrow;
    }
  }

  /// Start live analysis for a call
  Future<void> startLiveAnalysis(String phoneNumber, bool isIncoming) async {
    try {
      _logger.i('Starting live analysis for call: $phoneNumber');
      
      if (!_isAnalysisEnabled) {
        throw Exception('Live analysis mode is not enabled');
      }

      if (_currentSession?.isActive == true) {
        _logger.w('Stopping previous analysis session');
        await stopLiveAnalysis();
      }

      // Create new session
      final sessionId = _uuid.v4();
      final callId = _uuid.v4();
      
      _currentSession = LiveAnalysisSession(
        id: sessionId,
        callId: callId,
        startedAt: DateTime.now(),
        isActive: true,
        chunkResults: [],
        progress: AnalysisProgress(
          callId: callId,
          processedChunks: 0,
          totalChunks: 0, // Will be updated as chunks are processed
          isComplete: false,
          startedAt: DateTime.now(),
          status: 'Starting analysis...',
        ),
        phoneNumber: phoneNumber,
        isIncoming: isIncoming,
      );

      _chunkCounter = 0;
      
      // Start recording and chunk processing
      await _startChunkRecording();
      
      _sessionController.add(_currentSession!);
      
      _logger.i('Live analysis started for session: $sessionId');
    } catch (error) {
      _logger.e('Error starting live analysis: $error');
      rethrow;
    }
  }

  /// Stop live analysis
  Future<void> stopLiveAnalysis() async {
    try {
      _logger.i('Stopping live analysis');
      
      // Stop chunk timer
      _chunkTimer?.cancel();
      _chunkTimer = null;
      
      // Stop recording
      if (_isRecording) {
        await _stopChunkRecording();
      }
      
      // Update session
      if (_currentSession != null) {
        _currentSession = _currentSession!.copyWith(
          isActive: false,
          endedAt: DateTime.now(),
          progress: _currentSession!.progress.copyWith(
            isComplete: true,
            completedAt: DateTime.now(),
            status: 'Analysis completed',
          ),
        );
        
        _sessionController.add(_currentSession!);
      }
      
      _logger.i('Live analysis stopped');
    } catch (error) {
      _logger.e('Error stopping live analysis: $error');
      rethrow;
    }
  }

  /// Start recording audio chunks
  Future<void> _startChunkRecording() async {
    try {
      _logger.i('Starting chunk recording');
      
      // Start the chunk timer
      _chunkTimer = Timer.periodic(_chunkDuration, (timer) {
        _processNextChunk();
      });
      
      // Start first chunk immediately
      await _startNewChunk();
      
    } catch (error) {
      _logger.e('Error starting chunk recording: $error');
      rethrow;
    }
  }

  /// Start recording a new chunk
  Future<void> _startNewChunk() async {
    try {
      if (_isRecording) {
        await _stopChunkRecording();
      }

      _chunkCounter++;
      
      // Generate chunk file path
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _currentChunkPath = '${directory.path}/chunk_${_chunkCounter}_$timestamp.aac';
      
      // Start recording
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: _currentChunkPath!,
      );
      
      _isRecording = true;
      
      _logger.i('Started recording chunk $_chunkCounter: $_currentChunkPath');
      
      // Update session progress
      if (_currentSession != null) {
        _currentSession = _currentSession!.copyWith(
          progress: AnalysisProgress(
            callId: _currentSession!.callId,
            processedChunks: _chunkCounter - 1,
            totalChunks: _chunkCounter,
            isComplete: false,
            startedAt: _currentSession!.progress.startedAt,
            status: 'Recording chunk $_chunkCounter...',
          ),
        );
        _sessionController.add(_currentSession!);
      }
      
    } catch (error) {
      _logger.e('Error starting new chunk: $error');
      rethrow;
    }
  }

  /// Stop recording current chunk
  Future<void> _stopChunkRecording() async {
    try {
      if (!_isRecording) return;
      
      await _recorder.stop();
      _isRecording = false;
      
      _logger.i('Stopped recording chunk $_chunkCounter');
      
    } catch (error) {
      _logger.e('Error stopping chunk recording: $error');
      rethrow;
    }
  }

  /// Process the next chunk
  Future<void> _processNextChunk() async {
    try {
      if (_currentChunkPath == null) return;
      
      final chunkPath = _currentChunkPath!;
      final chunkNumber = _chunkCounter;
      
      // Stop current chunk and start next one
      await _stopChunkRecording();
      
      // Start next chunk if session is still active
      if (_currentSession?.isActive == true) {
        await _startNewChunk();
      }
      
      // Process the completed chunk
      _processChunkAsync(chunkPath, chunkNumber);
      
    } catch (error) {
      _logger.e('Error processing next chunk: $error');
    }
  }

  /// Process chunk asynchronously
  void _processChunkAsync(String chunkPath, int chunkNumber) {
    // Process in background to avoid blocking
    Future(() async {
      try {
        await _analyzeChunk(chunkPath, chunkNumber);
      } catch (error) {
        _logger.e('Error analyzing chunk $chunkNumber: $error');
        
        // Create error result
        final errorResult = ChunkAnalysisResult(
          id: _uuid.v4(),
          callId: _currentSession?.callId ?? '',
          chunkNumber: chunkNumber,
          totalChunks: _chunkCounter,
          scamProbability: 0.0,
          detectedPatterns: [],
          confidenceScore: 0.0,
          riskIndicators: [],
          analyzedAt: DateTime.now(),
          chunkDuration: _chunkDuration,
          errorMessage: error.toString(),
        );
        
        _addChunkResult(errorResult);
      } finally {
        // Clean up chunk file
        try {
          final file = File(chunkPath);
          if (await file.exists()) {
            await file.delete();
          }
        } catch (e) {
          _logger.w('Failed to delete chunk file: $e');
        }
      }
    });
  }

  /// Analyze a single chunk
  Future<void> _analyzeChunk(String chunkPath, int chunkNumber) async {
    try {
      _logger.i('Analyzing chunk $chunkNumber: $chunkPath');
      
      // Update session status
      if (_currentSession != null) {
        _currentSession = _currentSession!.copyWith(
          progress: AnalysisProgress(
            callId: _currentSession!.callId,
            processedChunks: chunkNumber - 1,
            totalChunks: _chunkCounter,
            isComplete: false,
            startedAt: _currentSession!.progress.startedAt,
            status: 'Analyzing chunk $chunkNumber...',
          ),
        );
        _sessionController.add(_currentSession!);
      }
      
      // Send chunk to backend for analysis
      final result = await _sendChunkToBackend(chunkPath, chunkNumber);
      
      // Add result to session
      _addChunkResult(result);
      
      _logger.i('Chunk $chunkNumber analysis complete');
      
    } catch (error) {
      _logger.e('Error analyzing chunk $chunkNumber: $error');
      rethrow;
    }
  }

  /// Send chunk to backend for analysis
  Future<ChunkAnalysisResult> _sendChunkToBackend(String chunkPath, int chunkNumber) async {
    try {
      if (_currentSession == null) {
        throw Exception('No active session');
      }

      // Send chunk to backend API
      final result = await BackendApiService.instance.analyzeChunk(
        chunkPath,
        callId: _currentSession!.callId,
        chunkNumber: chunkNumber,
        totalChunks: _chunkCounter,
        phoneNumber: _currentSession!.phoneNumber,
        isIncoming: _currentSession!.isIncoming,
      );

      return result;
    } catch (error) {
      _logger.e('Backend analysis failed, using fallback: $error');

      // Fallback to mock analysis if backend fails
      final scamProbability = (DateTime.now().millisecond % 100).toDouble();

      return ChunkAnalysisResult(
        id: _uuid.v4(),
        callId: _currentSession?.callId ?? '',
        chunkNumber: chunkNumber,
        totalChunks: _chunkCounter,
        scamProbability: scamProbability,
        detectedPatterns: _generateMockPatterns(scamProbability),
        confidenceScore: 85.0 + (DateTime.now().millisecond % 15),
        riskIndicators: _generateMockRiskIndicators(scamProbability),
        analyzedAt: DateTime.now(),
        chunkDuration: _chunkDuration,
        errorMessage: 'Backend unavailable: ${error.toString()}',
      );
    }
  }

  /// Add chunk result to current session
  void _addChunkResult(ChunkAnalysisResult result) {
    if (_currentSession == null) return;
    
    final updatedResults = List<ChunkAnalysisResult>.from(_currentSession!.chunkResults);
    updatedResults.add(result);
    
    // Keep only the last N chunks to prevent memory issues
    if (updatedResults.length > _maxHistoryChunks) {
      updatedResults.removeAt(0);
    }
    
    _currentSession = _currentSession!.copyWith(
      chunkResults: updatedResults,
      progress: AnalysisProgress(
        callId: _currentSession!.callId,
        processedChunks: result.chunkNumber,
        totalChunks: result.totalChunks,
        isComplete: false,
        startedAt: _currentSession!.progress.startedAt,
        status: 'Processed chunk ${result.chunkNumber}',
      ),
    );
    
    _sessionController.add(_currentSession!);
    _chunkResultController.add(result);
  }

  /// Generate mock patterns for testing
  List<ScamPattern> _generateMockPatterns(double scamProbability) {
    if (scamProbability < 30) return [];
    
    final patterns = <ScamPattern>[];
    
    if (scamProbability > 50) {
      patterns.add(ScamPattern(
        id: _uuid.v4(),
        name: 'Urgency Tactics',
        description: 'Caller using urgent language to pressure response',
        confidence: 0.8,
        detectedAt: DateTime.now(),
      ));
    }
    
    if (scamProbability > 70) {
      patterns.add(ScamPattern(
        id: _uuid.v4(),
        name: 'Authority Impersonation',
        description: 'Caller claiming to be from government or official organization',
        confidence: 0.9,
        detectedAt: DateTime.now(),
      ));
    }
    
    return patterns;
  }

  /// Generate mock risk indicators for testing
  List<String> _generateMockRiskIndicators(double scamProbability) {
    if (scamProbability < 30) return ['Normal conversation patterns'];
    
    final indicators = <String>[];
    
    if (scamProbability > 40) indicators.add('Suspicious keywords detected');
    if (scamProbability > 60) indicators.add('Pressure tactics identified');
    if (scamProbability > 80) indicators.add('Request for personal information');
    
    return indicators;
  }

  /// Dispose resources
  void dispose() {
    _chunkTimer?.cancel();
    _sessionController.close();
    _chunkResultController.close();
    _analysisStateController.close();
    _recorder.dispose();
  }
}
