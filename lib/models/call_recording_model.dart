import 'package:json_annotation/json_annotation.dart';

part 'call_recording_model.g.dart';

@JsonSerializable()
class CallRecording {
  final String id;
  final String phoneNumber;
  final String? contactName;
  final bool isIncoming;
  final DateTime timestamp;
  final Duration duration;
  final String fileName;
  final String filePath;
  final int fileSize;
  final AnalysisResult? analysisResult;
  final bool isAnalyzing;

  const CallRecording({
    required this.id,
    required this.phoneNumber,
    this.contactName,
    required this.isIncoming,
    required this.timestamp,
    required this.duration,
    required this.fileName,
    required this.filePath,
    required this.fileSize,
    this.analysisResult,
    this.isAnalyzing = false,
  });

  factory CallRecording.fromJson(Map<String, dynamic> json) =>
      _$CallRecordingFromJson(json);

  Map<String, dynamic> toJson() => _$CallRecordingToJson(this);

  CallRecording copyWith({
    String? id,
    String? phoneNumber,
    String? contactName,
    bool? isIncoming,
    DateTime? timestamp,
    Duration? duration,
    String? fileName,
    String? filePath,
    int? fileSize,
    AnalysisResult? analysisResult,
    bool? isAnalyzing,
  }) {
    return CallRecording(
      id: id ?? this.id,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      contactName: contactName ?? this.contactName,
      isIncoming: isIncoming ?? this.isIncoming,
      timestamp: timestamp ?? this.timestamp,
      duration: duration ?? this.duration,
      fileName: fileName ?? this.fileName,
      filePath: filePath ?? this.filePath,
      fileSize: fileSize ?? this.fileSize,
      analysisResult: analysisResult ?? this.analysisResult,
      isAnalyzing: isAnalyzing ?? this.isAnalyzing,
    );
  }

  String get formattedDuration {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String get formattedFileSize {
    if (fileSize < 1024) {
      return '${fileSize}B';
    } else if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)}KB';
    } else {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
  }

  String get callTypeText => isIncoming ? 'Incoming' : 'Outgoing';
}

@JsonSerializable()
class AnalysisResult {
  final String id;
  final double confidenceScore;
  final String scamType;
  final String riskLevel;
  final bool isScam;
  final DateTime analysisTimestamp;
  final List<String> keywords;
  final List<String> flags;

  const AnalysisResult({
    required this.id,
    required this.confidenceScore,
    required this.scamType,
    required this.riskLevel,
    required this.isScam,
    required this.analysisTimestamp,
    required this.keywords,
    required this.flags,
  });

  factory AnalysisResult.fromJson(Map<String, dynamic> json) =>
      _$AnalysisResultFromJson(json);

  Map<String, dynamic> toJson() => _$AnalysisResultToJson(this);

  String get riskLevelText {
    switch (riskLevel.toUpperCase()) {
      case 'LOW':
        return 'Low Risk';
      case 'MEDIUM':
        return 'Medium Risk';
      case 'HIGH':
        return 'High Risk';
      case 'CRITICAL':
        return 'Critical Risk';
      default:
        return 'Unknown Risk';
    }
  }

  String get scamTypeText {
    switch (scamType.toUpperCase()) {
      case 'ROBOCALL':
        return 'Robocall';
      case 'PHISHING':
        return 'Phishing';
      case 'TECH_SUPPORT':
        return 'Tech Support Scam';
      case 'IRS_SCAM':
        return 'IRS Scam';
      case 'LOTTERY_SCAM':
        return 'Lottery Scam';
      case 'ROMANCE_SCAM':
        return 'Romance Scam';
      case 'INVESTMENT_FRAUD':
        return 'Investment Fraud';
      case 'CHARITY_SCAM':
        return 'Charity Scam';
      case 'LEGITIMATE':
        return 'Legitimate Call';
      default:
        return scamType;
    }
  }
}
