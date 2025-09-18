import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

import '../models/call_recording_model.dart';
import '../models/live_analysis_models.dart';

class BackendApiService {
  static final BackendApiService _instance = BackendApiService._internal();
  static BackendApiService get instance => _instance;
  BackendApiService._internal();

  final Logger _logger = Logger();
  
  // Backend server configuration
  static const String _baseUrl = 'http://localhost:3000';
  static const Duration _timeout = Duration(seconds: 30);

  Future<AnalysisResult> analyzeAudio(
    String audioFilePath, {
    String? phoneNumber,
    String? callType,
    int? callDuration,
    String? timestamp,
  }) async {
    try {
      _logger.i('Starting audio analysis for: $audioFilePath');

      final uri = Uri.parse('$_baseUrl/analyze-audio');
      final request = http.MultipartRequest('POST', uri);

      // Add audio file
      final audioFile = File(audioFilePath);
      if (!await audioFile.exists()) {
        throw Exception('Audio file not found: $audioFilePath');
      }

      final multipartFile = await http.MultipartFile.fromPath(
        'audio',
        audioFilePath,
        filename: audioFile.path.split('/').last,
      );
      request.files.add(multipartFile);

      // Add metadata
      if (phoneNumber != null) request.fields['phoneNumber'] = phoneNumber;
      if (callType != null) request.fields['callType'] = callType;
      if (callDuration != null) request.fields['callDuration'] = callDuration.toString();
      if (timestamp != null) request.fields['timestamp'] = timestamp;

      _logger.i('Sending request to: $uri');
      _logger.i('File size: ${await audioFile.length()} bytes');

      // Send request
      final streamedResponse = await request.send().timeout(_timeout);
      final response = await http.Response.fromStream(streamedResponse);

      _logger.i('Response status: ${response.statusCode}');
      _logger.i('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        
        if (responseData['success'] == true && responseData['analysis'] != null) {
          final analysisData = responseData['analysis'];
          
          return AnalysisResult(
            id: analysisData['id'],
            confidenceScore: (analysisData['confidenceScore'] as num).toDouble(),
            scamType: analysisData['scamType'],
            riskLevel: analysisData['riskLevel'],
            isScam: analysisData['isScam'],
            analysisTimestamp: DateTime.parse(analysisData['analysisTimestamp']),
            keywords: List<String>.from(analysisData['keywords'] ?? []),
            flags: List<String>.from(analysisData['flags'] ?? []),
          );
        } else {
          throw Exception('Invalid response format from server');
        }
      } else {
        final errorData = json.decode(response.body);
        throw Exception('Server error: ${errorData['error'] ?? 'Unknown error'}');
      }
    } catch (error) {
      _logger.e('Error analyzing audio: $error');
      rethrow;
    }
  }

  Future<List<AnalysisResult>> getAnalysisHistory({
    int? limit,
    bool? scamOnly,
  }) async {
    try {
      _logger.i('Fetching analysis history');

      final queryParams = <String, String>{};
      if (limit != null) queryParams['limit'] = limit.toString();
      if (scamOnly != null) queryParams['scamOnly'] = scamOnly.toString();

      final uri = Uri.parse('$_baseUrl/get-analysis-history').replace(
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      _logger.i('Request URL: $uri');

      final response = await http.get(uri).timeout(_timeout);

      _logger.i('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        
        if (responseData['success'] == true && responseData['history'] != null) {
          final List<dynamic> historyData = responseData['history'];
          
          return historyData.map((data) => AnalysisResult(
            id: data['id'],
            confidenceScore: (data['confidenceScore'] as num).toDouble(),
            scamType: data['scamType'],
            riskLevel: data['riskLevel'],
            isScam: data['isScam'],
            analysisTimestamp: DateTime.parse(data['analysisTimestamp']),
            keywords: List<String>.from(data['keywords'] ?? []),
            flags: List<String>.from(data['flags'] ?? []),
          )).toList();
        } else {
          throw Exception('Invalid response format from server');
        }
      } else {
        final errorData = json.decode(response.body);
        throw Exception('Server error: ${errorData['error'] ?? 'Unknown error'}');
      }
    } catch (error) {
      _logger.e('Error fetching analysis history: $error');
      rethrow;
    }
  }

  Future<AnalysisResult> updateAnalysisStatus(
    String analysisId,
    Map<String, dynamic> updates,
  ) async {
    try {
      _logger.i('Updating analysis status: $analysisId');

      final uri = Uri.parse('$_baseUrl/update-analysis-status/$analysisId');
      
      final response = await http.put(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(updates),
      ).timeout(_timeout);

      _logger.i('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        
        if (responseData['success'] == true && responseData['analysis'] != null) {
          final analysisData = responseData['analysis'];
          
          return AnalysisResult(
            id: analysisData['id'],
            confidenceScore: (analysisData['confidenceScore'] as num).toDouble(),
            scamType: analysisData['scamType'],
            riskLevel: analysisData['riskLevel'],
            isScam: analysisData['isScam'],
            analysisTimestamp: DateTime.parse(analysisData['analysisTimestamp']),
            keywords: List<String>.from(analysisData['keywords'] ?? []),
            flags: List<String>.from(analysisData['flags'] ?? []),
          );
        } else {
          throw Exception('Invalid response format from server');
        }
      } else {
        final errorData = json.decode(response.body);
        throw Exception('Server error: ${errorData['error'] ?? 'Unknown error'}');
      }
    } catch (error) {
      _logger.e('Error updating analysis status: $error');
      rethrow;
    }
  }

  Future<bool> checkServerHealth() async {
    try {
      _logger.i('Checking server health');

      final uri = Uri.parse('$_baseUrl/health');
      final response = await http.get(uri).timeout(const Duration(seconds: 5));

      _logger.i('Health check response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        _logger.i('Server status: ${responseData['status']}');
        return responseData['status'] == 'OK';
      }

      return false;
    } catch (error) {
      _logger.e('Server health check failed: $error');
      return false;
    }
  }

  /// Analyze audio chunk for live analysis
  Future<ChunkAnalysisResult> analyzeChunk(
    String audioChunkPath, {
    required String callId,
    required int chunkNumber,
    int? totalChunks,
    String? phoneNumber,
    bool? isIncoming,
  }) async {
    try {
      _logger.i('Starting chunk analysis: chunk $chunkNumber for call $callId');

      final uri = Uri.parse('$_baseUrl/analyze-chunk');
      final request = http.MultipartRequest('POST', uri);

      // Add audio chunk file
      final audioFile = File(audioChunkPath);
      if (!await audioFile.exists()) {
        throw Exception('Audio chunk file not found: $audioChunkPath');
      }

      final multipartFile = await http.MultipartFile.fromPath(
        'audio',
        audioChunkPath,
        filename: audioFile.path.split('/').last,
      );
      request.files.add(multipartFile);

      // Add chunk metadata
      request.fields['call_id'] = callId;
      request.fields['chunk_number'] = chunkNumber.toString();
      if (totalChunks != null) request.fields['total_chunks'] = totalChunks.toString();
      if (phoneNumber != null) request.fields['phone_number'] = phoneNumber;
      if (isIncoming != null) request.fields['is_incoming'] = isIncoming.toString();

      _logger.i('Sending chunk request to: $uri');
      _logger.i('Chunk file size: ${await audioFile.length()} bytes');

      // Send request with shorter timeout for chunks
      final streamedResponse = await request.send().timeout(const Duration(seconds: 15));
      final response = await http.Response.fromStream(streamedResponse);

      _logger.i('Chunk response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['success'] == true && responseData['chunk_analysis'] != null) {
          final chunkData = responseData['chunk_analysis'];
          return ChunkAnalysisResult.fromJson(chunkData);
        } else {
          throw Exception('Invalid chunk analysis response format from server');
        }
      } else {
        final errorData = json.decode(response.body);
        throw Exception('Server error: ${errorData['error'] ?? 'Unknown error'}');
      }
    } catch (error) {
      _logger.e('Error analyzing chunk: $error');
      rethrow;
    }
  }

  /// Start live analysis session
  Future<String> startLiveAnalysisSession({
    required String callId,
    String? phoneNumber,
    bool? isIncoming,
  }) async {
    try {
      _logger.i('Starting live analysis session for call: $callId');

      final uri = Uri.parse('$_baseUrl/start-live-analysis');

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'call_id': callId,
          'phone_number': phoneNumber,
          'is_incoming': isIncoming,
        }),
      ).timeout(_timeout);

      _logger.i('Start session response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['success'] == true && responseData['session'] != null) {
          final sessionData = responseData['session'];
          return sessionData['id'];
        } else {
          throw Exception('Invalid session response format from server');
        }
      } else {
        final errorData = json.decode(response.body);
        throw Exception('Server error: ${errorData['error'] ?? 'Unknown error'}');
      }
    } catch (error) {
      _logger.e('Error starting live analysis session: $error');
      rethrow;
    }
  }

  /// Stop live analysis session
  Future<void> stopLiveAnalysisSession(String callId) async {
    try {
      _logger.i('Stopping live analysis session for call: $callId');

      final uri = Uri.parse('$_baseUrl/stop-live-analysis');

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'call_id': callId,
        }),
      ).timeout(_timeout);

      _logger.i('Stop session response status: ${response.statusCode}');

      if (response.statusCode != 200) {
        final errorData = json.decode(response.body);
        throw Exception('Server error: ${errorData['error'] ?? 'Unknown error'}');
      }
    } catch (error) {
      _logger.e('Error stopping live analysis session: $error');
      rethrow;
    }
  }

  /// Re-analyze saved recording in chunks
  Future<List<ChunkAnalysisResult>> reAnalyzeRecording(
    String audioFilePath, {
    required String callId,
    String? phoneNumber,
    bool? isIncoming,
    Duration chunkDuration = const Duration(seconds: 10),
  }) async {
    try {
      _logger.i('Starting re-analysis of recording: $audioFilePath');

      // For now, simulate chunking by creating multiple analysis requests
      // In a real implementation, you would split the audio file into chunks

      final results = <ChunkAnalysisResult>[];
      const totalChunks = 5; // Simulate 5 chunks for demo

      for (int i = 1; i <= totalChunks; i++) {
        // Simulate processing delay
        await Future.delayed(const Duration(seconds: 1));

        // For demo, we'll send the same file multiple times with different chunk numbers
        final result = await analyzeChunk(
          audioFilePath,
          callId: callId,
          chunkNumber: i,
          totalChunks: totalChunks,
          phoneNumber: phoneNumber,
          isIncoming: isIncoming,
        );

        results.add(result);
      }

      return results;
    } catch (error) {
      _logger.e('Error re-analyzing recording: $error');
      rethrow;
    }
  }
}
