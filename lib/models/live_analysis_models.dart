import 'package:flutter/material.dart';

/// Enum for threat levels with color coding
enum ThreatLevel {
  low,
  medium,
  high,
  critical;

  Color get color {
    switch (this) {
      case ThreatLevel.low:
        return Colors.green;
      case ThreatLevel.medium:
        return Colors.orange;
      case ThreatLevel.high:
        return Colors.red;
      case ThreatLevel.critical:
        return Colors.red.shade900;
    }
  }

  String get label {
    switch (this) {
      case ThreatLevel.low:
        return 'Low Risk';
      case ThreatLevel.medium:
        return 'Medium Risk';
      case ThreatLevel.high:
        return 'High Risk';
      case ThreatLevel.critical:
        return 'Critical Risk';
    }
  }

  static ThreatLevel fromPercentage(double percentage) {
    if (percentage >= 71) return ThreatLevel.critical;
    if (percentage >= 51) return ThreatLevel.high;
    if (percentage >= 31) return ThreatLevel.medium;
    return ThreatLevel.low;
  }
}

/// Represents a detected scam pattern
class ScamPattern {
  final String id;
  final String name;
  final String description;
  final double confidence;
  final DateTime detectedAt;

  const ScamPattern({
    required this.id,
    required this.name,
    required this.description,
    required this.confidence,
    required this.detectedAt,
  });

  factory ScamPattern.fromJson(Map<String, dynamic> json) {
    return ScamPattern(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      confidence: (json['confidence'] as num).toDouble(),
      detectedAt: DateTime.parse(json['detected_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'confidence': confidence,
      'detected_at': detectedAt.toIso8601String(),
    };
  }
}

/// Represents analysis result for a single audio chunk
class ChunkAnalysisResult {
  final String id;
  final String callId;
  final int chunkNumber;
  final int totalChunks;
  final double scamProbability;
  final List<ScamPattern> detectedPatterns;
  final double confidenceScore;
  final List<String> riskIndicators;
  final DateTime analyzedAt;
  final Duration chunkDuration;
  final String? errorMessage;

  const ChunkAnalysisResult({
    required this.id,
    required this.callId,
    required this.chunkNumber,
    required this.totalChunks,
    required this.scamProbability,
    required this.detectedPatterns,
    required this.confidenceScore,
    required this.riskIndicators,
    required this.analyzedAt,
    required this.chunkDuration,
    this.errorMessage,
  });

  ThreatLevel get threatLevel => ThreatLevel.fromPercentage(scamProbability);

  bool get isComplete => chunkNumber == totalChunks;

  factory ChunkAnalysisResult.fromJson(Map<String, dynamic> json) {
    return ChunkAnalysisResult(
      id: json['chunk_analysis_id'],
      callId: json['call_id'],
      chunkNumber: json['chunk_number'],
      totalChunks: json['total_chunks'],
      scamProbability: (json['scam_probability'] as num).toDouble(),
      detectedPatterns: (json['detected_patterns'] as List<dynamic>?)
          ?.map((pattern) => ScamPattern.fromJson(pattern))
          .toList() ?? [],
      confidenceScore: (json['confidence_score'] as num).toDouble(),
      riskIndicators: List<String>.from(json['risk_indicators'] ?? []),
      analyzedAt: DateTime.parse(json['analyzed_at']),
      chunkDuration: Duration(seconds: json['chunk_duration_seconds'] ?? 10),
      errorMessage: json['error_message'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'chunk_analysis_id': id,
      'call_id': callId,
      'chunk_number': chunkNumber,
      'total_chunks': totalChunks,
      'scam_probability': scamProbability,
      'detected_patterns': detectedPatterns.map((p) => p.toJson()).toList(),
      'confidence_score': confidenceScore,
      'risk_indicators': riskIndicators,
      'analyzed_at': analyzedAt.toIso8601String(),
      'chunk_duration_seconds': chunkDuration.inSeconds,
      'error_message': errorMessage,
    };
  }
}

/// Represents the progress of ongoing analysis
class AnalysisProgress {
  final String callId;
  final int processedChunks;
  final int totalChunks;
  final bool isComplete;
  final DateTime startedAt;
  final DateTime? completedAt;
  final String status;

  const AnalysisProgress({
    required this.callId,
    required this.processedChunks,
    required this.totalChunks,
    required this.isComplete,
    required this.startedAt,
    this.completedAt,
    required this.status,
  });

  double get progressPercentage {
    if (totalChunks == 0) return 0.0;
    return (processedChunks / totalChunks).clamp(0.0, 1.0);
  }

  String get progressText => '$processedChunks of $totalChunks chunks processed';

  factory AnalysisProgress.fromJson(Map<String, dynamic> json) {
    return AnalysisProgress(
      callId: json['call_id'],
      processedChunks: json['processed_chunks'],
      totalChunks: json['total_chunks'],
      isComplete: json['is_complete'],
      startedAt: DateTime.parse(json['started_at']),
      completedAt: json['completed_at'] != null 
          ? DateTime.parse(json['completed_at'])
          : null,
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'call_id': callId,
      'processed_chunks': processedChunks,
      'total_chunks': totalChunks,
      'is_complete': isComplete,
      'started_at': startedAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'status': status,
    };
  }

  AnalysisProgress copyWith({
    String? callId,
    int? processedChunks,
    int? totalChunks,
    bool? isComplete,
    DateTime? startedAt,
    DateTime? completedAt,
    String? status,
  }) {
    return AnalysisProgress(
      callId: callId ?? this.callId,
      processedChunks: processedChunks ?? this.processedChunks,
      totalChunks: totalChunks ?? this.totalChunks,
      isComplete: isComplete ?? this.isComplete,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      status: status ?? this.status,
    );
  }
}

/// Represents a live analysis session
class LiveAnalysisSession {
  final String id;
  final String callId;
  final DateTime startedAt;
  final DateTime? endedAt;
  final bool isActive;
  final List<ChunkAnalysisResult> chunkResults;
  final AnalysisProgress progress;
  final String phoneNumber;
  final bool isIncoming;

  const LiveAnalysisSession({
    required this.id,
    required this.callId,
    required this.startedAt,
    this.endedAt,
    required this.isActive,
    required this.chunkResults,
    required this.progress,
    required this.phoneNumber,
    required this.isIncoming,
  });

  /// Get the latest chunk analysis result
  ChunkAnalysisResult? get latestResult => 
      chunkResults.isNotEmpty ? chunkResults.last : null;

  /// Get overall scam probability based on all chunks
  double get overallScamProbability {
    if (chunkResults.isEmpty) return 0.0;
    
    // Calculate weighted average with more recent chunks having higher weight
    double totalWeight = 0.0;
    double weightedSum = 0.0;
    
    for (int i = 0; i < chunkResults.length; i++) {
      final weight = (i + 1).toDouble(); // More recent chunks have higher weight
      totalWeight += weight;
      weightedSum += chunkResults[i].scamProbability * weight;
    }
    
    return totalWeight > 0 ? weightedSum / totalWeight : 0.0;
  }

  /// Get all unique detected patterns across chunks
  List<ScamPattern> get allDetectedPatterns {
    final patterns = <String, ScamPattern>{};
    
    for (final chunk in chunkResults) {
      for (final pattern in chunk.detectedPatterns) {
        patterns[pattern.id] = pattern;
      }
    }
    
    return patterns.values.toList();
  }

  /// Get current threat level
  ThreatLevel get currentThreatLevel => 
      ThreatLevel.fromPercentage(overallScamProbability);

  factory LiveAnalysisSession.fromJson(Map<String, dynamic> json) {
    return LiveAnalysisSession(
      id: json['id'],
      callId: json['call_id'],
      startedAt: DateTime.parse(json['started_at']),
      endedAt: json['ended_at'] != null 
          ? DateTime.parse(json['ended_at'])
          : null,
      isActive: json['is_active'],
      chunkResults: (json['chunk_results'] as List<dynamic>?)
          ?.map((chunk) => ChunkAnalysisResult.fromJson(chunk))
          .toList() ?? [],
      progress: AnalysisProgress.fromJson(json['progress']),
      phoneNumber: json['phone_number'],
      isIncoming: json['is_incoming'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'call_id': callId,
      'started_at': startedAt.toIso8601String(),
      'ended_at': endedAt?.toIso8601String(),
      'is_active': isActive,
      'chunk_results': chunkResults.map((c) => c.toJson()).toList(),
      'progress': progress.toJson(),
      'phone_number': phoneNumber,
      'is_incoming': isIncoming,
    };
  }

  LiveAnalysisSession copyWith({
    String? id,
    String? callId,
    DateTime? startedAt,
    DateTime? endedAt,
    bool? isActive,
    List<ChunkAnalysisResult>? chunkResults,
    AnalysisProgress? progress,
    String? phoneNumber,
    bool? isIncoming,
  }) {
    return LiveAnalysisSession(
      id: id ?? this.id,
      callId: callId ?? this.callId,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      isActive: isActive ?? this.isActive,
      chunkResults: chunkResults ?? this.chunkResults,
      progress: progress ?? this.progress,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      isIncoming: isIncoming ?? this.isIncoming,
    );
  }
}
