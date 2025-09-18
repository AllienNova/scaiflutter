import 'package:json_annotation/json_annotation.dart';

part 'call_model.g.dart';

enum CallStatus {
  incoming,
  active,
  ended,
  missed,
  rejected,
}

@JsonSerializable()
class CallModel {
  final String id;
  final String phoneNumber;
  final String contactName;
  final bool isIncoming;
  final DateTime startTime;
  final DateTime? endTime;
  final Duration? duration;
  final CallStatus status;
  final String? recordingPath;
  final List<AnalysisResult>? analysisResults;
  final bool isScamSuspected;
  final double? scamConfidence;
  
  const CallModel({
    required this.id,
    required this.phoneNumber,
    required this.contactName,
    required this.isIncoming,
    required this.startTime,
    this.endTime,
    this.duration,
    required this.status,
    this.recordingPath,
    this.analysisResults,
    this.isScamSuspected = false,
    this.scamConfidence,
  });
  
  CallModel copyWith({
    String? id,
    String? phoneNumber,
    String? contactName,
    bool? isIncoming,
    DateTime? startTime,
    DateTime? endTime,
    Duration? duration,
    CallStatus? status,
    String? recordingPath,
    List<AnalysisResult>? analysisResults,
    bool? isScamSuspected,
    double? scamConfidence,
  }) {
    return CallModel(
      id: id ?? this.id,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      contactName: contactName ?? this.contactName,
      isIncoming: isIncoming ?? this.isIncoming,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      duration: duration ?? this.duration,
      status: status ?? this.status,
      recordingPath: recordingPath ?? this.recordingPath,
      analysisResults: analysisResults ?? this.analysisResults,
      isScamSuspected: isScamSuspected ?? this.isScamSuspected,
      scamConfidence: scamConfidence ?? this.scamConfidence,
    );
  }
  
  factory CallModel.fromJson(Map<String, dynamic> json) => _$CallModelFromJson(json);
  Map<String, dynamic> toJson() => _$CallModelToJson(this);
  
  String get formattedDuration {
    if (duration == null) return '00:00';
    
    final minutes = duration!.inMinutes.remainder(60);
    final seconds = duration!.inSeconds.remainder(60);
    
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
  
  String get statusText {
    switch (status) {
      case CallStatus.incoming:
        return 'Incoming';
      case CallStatus.active:
        return 'Active';
      case CallStatus.ended:
        return 'Ended';
      case CallStatus.missed:
        return 'Missed';
      case CallStatus.rejected:
        return 'Rejected';
    }
  }
}

@JsonSerializable()
class AnalysisResult {
  final String id;
  final String callId;
  final DateTime timestamp;
  final AnalysisType type;
  final double confidence;
  final Map<String, dynamic> details;
  final bool isScamIndicator;
  
  const AnalysisResult({
    required this.id,
    required this.callId,
    required this.timestamp,
    required this.type,
    required this.confidence,
    required this.details,
    required this.isScamIndicator,
  });
  
  factory AnalysisResult.fromJson(Map<String, dynamic> json) => _$AnalysisResultFromJson(json);
  Map<String, dynamic> toJson() => _$AnalysisResultToJson(this);
}

enum AnalysisType {
  deepfakeDetection,
  sentimentAnalysis,
  voiceAuthentication,
  scamPatternDetection,
  stressAnalysis,
  emotionDetection,
}