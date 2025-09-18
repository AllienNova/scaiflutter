// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'call_recording_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CallRecording _$CallRecordingFromJson(Map<String, dynamic> json) =>
    CallRecording(
      id: json['id'] as String,
      phoneNumber: json['phoneNumber'] as String,
      contactName: json['contactName'] as String?,
      isIncoming: json['isIncoming'] as bool,
      timestamp: DateTime.parse(json['timestamp'] as String),
      duration: Duration(microseconds: (json['duration'] as num).toInt()),
      fileName: json['fileName'] as String,
      filePath: json['filePath'] as String,
      fileSize: (json['fileSize'] as num).toInt(),
      analysisResult: json['analysisResult'] == null
          ? null
          : AnalysisResult.fromJson(
              json['analysisResult'] as Map<String, dynamic>,
            ),
      isAnalyzing: json['isAnalyzing'] as bool? ?? false,
    );

Map<String, dynamic> _$CallRecordingToJson(CallRecording instance) =>
    <String, dynamic>{
      'id': instance.id,
      'phoneNumber': instance.phoneNumber,
      'contactName': instance.contactName,
      'isIncoming': instance.isIncoming,
      'timestamp': instance.timestamp.toIso8601String(),
      'duration': instance.duration.inMicroseconds,
      'fileName': instance.fileName,
      'filePath': instance.filePath,
      'fileSize': instance.fileSize,
      'analysisResult': instance.analysisResult,
      'isAnalyzing': instance.isAnalyzing,
    };

AnalysisResult _$AnalysisResultFromJson(Map<String, dynamic> json) =>
    AnalysisResult(
      id: json['id'] as String,
      confidenceScore: (json['confidenceScore'] as num).toDouble(),
      scamType: json['scamType'] as String,
      riskLevel: json['riskLevel'] as String,
      isScam: json['isScam'] as bool,
      analysisTimestamp: DateTime.parse(json['analysisTimestamp'] as String),
      keywords: (json['keywords'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      flags: (json['flags'] as List<dynamic>).map((e) => e as String).toList(),
    );

Map<String, dynamic> _$AnalysisResultToJson(AnalysisResult instance) =>
    <String, dynamic>{
      'id': instance.id,
      'confidenceScore': instance.confidenceScore,
      'scamType': instance.scamType,
      'riskLevel': instance.riskLevel,
      'isScam': instance.isScam,
      'analysisTimestamp': instance.analysisTimestamp.toIso8601String(),
      'keywords': instance.keywords,
      'flags': instance.flags,
    };
