import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../core/constants.dart';
import '../models/call_model.dart';

class TheHiveApiService {
  static final TheHiveApiService _instance = TheHiveApiService._internal();
  static TheHiveApiService get instance => _instance;
  TheHiveApiService._internal();
  
  final Logger _logger = Logger();
  late final Dio _dio;
  
  void _initializeDio() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.theHiveApiBaseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
      headers: {
        'Authorization': 'Bearer ${AppConstants.theHiveApiKey}',
        'Content-Type': 'application/json',
      },
    ));
    
    _dio.interceptors.add(LogInterceptor(
      requestBody: false,
      responseBody: false,
      logPrint: (log) => _logger.d(log),
    ));
    
    _dio.interceptors.add(InterceptorsWrapper(
      onError: (error, handler) {
        _logger.e('API Error: ${error.message}');
        handler.next(error);
      },
    ));
  }
  
  Future<List<AnalysisResult>> analyzeAudioChunk(String audioFilePath) async {
    try {
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity == ConnectivityResult.none) {
        _logger.w('No internet connection available');
        return [];
      }
      
      _initializeDio();
      
      final audioFile = File(audioFilePath);
      if (!await audioFile.exists()) {
        _logger.e('Audio file does not exist: $audioFilePath');
        return [];
      }
      
      final results = <AnalysisResult>[];
      
      final deepfakeResult = await _detectDeepfake(audioFile);
      if (deepfakeResult != null) results.add(deepfakeResult);
      
      final sentimentResult = await _analyzeSentiment(audioFile);
      if (sentimentResult != null) results.add(sentimentResult);
      
      final scamPatternResult = await _detectScamPatterns(audioFile);
      if (scamPatternResult != null) results.add(scamPatternResult);
      
      final voiceAuthResult = await _authenticateVoice(audioFile);
      if (voiceAuthResult != null) results.add(voiceAuthResult);
      
      return results;
    } catch (e) {
      _logger.e('Error analyzing audio chunk: $e');
      return [];
    }
  }
  
  Future<AnalysisResult?> _detectDeepfake(File audioFile) async {
    try {
      final formData = FormData.fromMap({
        'audio': await MultipartFile.fromFile(
          audioFile.path,
          filename: 'audio_chunk.wav',
        ),
        'model': 'deepfake-v2',
        'sensitivity': 'high',
      });
      
      final response = await _dio.post(
        ApiEndpoints.deepfakeDetection,
        data: formData,
        options: Options(
          headers: {'Content-Type': 'multipart/form-data'},
        ),
      );
      
      if (response.statusCode == 200) {
        final data = response.data;
        final confidence = (data['confidence'] as num).toDouble();
        final isDeepfake = data['is_deepfake'] as bool;
        
        return AnalysisResult(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          callId: _extractCallIdFromPath(audioFile.path),
          timestamp: DateTime.now(),
          type: AnalysisType.deepfakeDetection,
          confidence: confidence,
          details: {
            'is_deepfake': isDeepfake,
            'model_version': data['model_version'],
            'processing_time': data['processing_time'],
            'features': data['features'] ?? {},
          },
          isScamIndicator: isDeepfake && confidence > 0.7,
        );
      }
    } catch (e) {
      _logger.e('Error detecting deepfake: $e');
    }
    return null;
  }
  
  Future<AnalysisResult?> _analyzeSentiment(File audioFile) async {
    try {
      final formData = FormData.fromMap({
        'audio': await MultipartFile.fromFile(
          audioFile.path,
          filename: 'audio_chunk.wav',
        ),
        'include_emotions': true,
        'include_stress_level': true,
      });
      
      final response = await _dio.post(
        ApiEndpoints.sentimentAnalysis,
        data: formData,
        options: Options(
          headers: {'Content-Type': 'multipart/form-data'},
        ),
      );
      
      if (response.statusCode == 200) {
        final data = response.data;
        final sentiment = data['sentiment'];
        final confidence = (data['confidence'] as num).toDouble();
        final stressLevel = (data['stress_level'] as num?)?.toDouble() ?? 0.0;
        
        return AnalysisResult(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          callId: _extractCallIdFromPath(audioFile.path),
          timestamp: DateTime.now(),
          type: AnalysisType.sentimentAnalysis,
          confidence: confidence,
          details: {
            'sentiment': sentiment,
            'emotions': data['emotions'] ?? {},
            'stress_level': stressLevel,
            'arousal': data['arousal'],
            'valence': data['valence'],
          },
          isScamIndicator: stressLevel > 0.8 || sentiment == 'aggressive',
        );
      }
    } catch (e) {
      _logger.e('Error analyzing sentiment: $e');
    }
    return null;
  }
  
  Future<AnalysisResult?> _detectScamPatterns(File audioFile) async {
    try {
      final formData = FormData.fromMap({
        'audio': await MultipartFile.fromFile(
          audioFile.path,
          filename: 'audio_chunk.wav',
        ),
        'patterns': [
          'urgent_payment',
          'personal_info_request',
          'bank_details',
          'government_threat',
          'tech_support',
        ],
        'language': 'en',
      });
      
      final response = await _dio.post(
        ApiEndpoints.scamPatternDetection,
        data: formData,
        options: Options(
          headers: {'Content-Type': 'multipart/form-data'},
        ),
      );
      
      if (response.statusCode == 200) {
        final data = response.data;
        final detectedPatterns = List<String>.from(data['detected_patterns'] ?? []);
        final confidence = (data['overall_confidence'] as num).toDouble();
        
        return AnalysisResult(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          callId: _extractCallIdFromPath(audioFile.path),
          timestamp: DateTime.now(),
          type: AnalysisType.scamPatternDetection,
          confidence: confidence,
          details: {
            'detected_patterns': detectedPatterns,
            'pattern_scores': data['pattern_scores'] ?? {},
            'transcript_segments': data['transcript_segments'] ?? [],
            'keywords': data['keywords'] ?? [],
          },
          isScamIndicator: detectedPatterns.isNotEmpty && confidence > 0.6,
        );
      }
    } catch (e) {
      _logger.e('Error detecting scam patterns: $e');
    }
    return null;
  }
  
  Future<AnalysisResult?> _authenticateVoice(File audioFile) async {
    try {
      final formData = FormData.fromMap({
        'audio': await MultipartFile.fromFile(
          audioFile.path,
          filename: 'audio_chunk.wav',
        ),
        'check_synthesis': true,
        'check_conversion': true,
      });
      
      final response = await _dio.post(
        ApiEndpoints.voiceAuthentication,
        data: formData,
        options: Options(
          headers: {'Content-Type': 'multipart/form-data'},
        ),
      );
      
      if (response.statusCode == 200) {
        final data = response.data;
        final isAuthentic = data['is_authentic'] as bool;
        final confidence = (data['confidence'] as num).toDouble();
        
        return AnalysisResult(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          callId: _extractCallIdFromPath(audioFile.path),
          timestamp: DateTime.now(),
          type: AnalysisType.voiceAuthentication,
          confidence: confidence,
          details: {
            'is_authentic': isAuthentic,
            'synthesis_probability': data['synthesis_probability'],
            'conversion_probability': data['conversion_probability'],
            'quality_score': data['quality_score'],
          },
          isScamIndicator: !isAuthentic && confidence > 0.7,
        );
      }
    } catch (e) {
      _logger.e('Error authenticating voice: $e');
    }
    return null;
  }
  
  String _extractCallIdFromPath(String path) {
    final parts = path.split('_');
    if (parts.length >= 2) {
      return parts[1];
    }
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
  
  Future<bool> testConnection() async {
    try {
      _initializeDio();
      final response = await _dio.get('/health');
      return response.statusCode == 200;
    } catch (e) {
      _logger.e('Connection test failed: $e');
      return false;
    }
  }
  
  Future<Map<String, dynamic>?> getApiStatus() async {
    try {
      _initializeDio();
      final response = await _dio.get('/status');
      if (response.statusCode == 200) {
        return response.data;
      }
    } catch (e) {
      _logger.e('Error getting API status: $e');
    }
    return null;
  }
}