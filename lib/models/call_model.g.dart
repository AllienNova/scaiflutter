// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'call_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CallModel _$CallModelFromJson(Map<String, dynamic> json) => CallModel(
  id: json['id'] as String,
  phoneNumber: json['phoneNumber'] as String,
  contactName: json['contactName'] as String,
  isIncoming: json['isIncoming'] as bool,
  startTime: DateTime.parse(json['startTime'] as String),
  endTime: json['endTime'] == null
      ? null
      : DateTime.parse(json['endTime'] as String),
  duration: json['duration'] == null
      ? null
      : Duration(microseconds: (json['duration'] as num).toInt()),
  status: $enumDecode(_$CallStatusEnumMap, json['status']),
  recordingPath: json['recordingPath'] as String?,
  analysisResults: (json['analysisResults'] as List<dynamic>?)
      ?.map((e) => AnalysisResult.fromJson(e as Map<String, dynamic>))
      .toList(),
  isScamSuspected: json['isScamSuspected'] as bool? ?? false,
  scamConfidence: (json['scamConfidence'] as num?)?.toDouble(),
);

Map<String, dynamic> _$CallModelToJson(CallModel instance) => <String, dynamic>{
  'id': instance.id,
  'phoneNumber': instance.phoneNumber,
  'contactName': instance.contactName,
  'isIncoming': instance.isIncoming,
  'startTime': instance.startTime.toIso8601String(),
  'endTime': instance.endTime?.toIso8601String(),
  'duration': instance.duration?.inMicroseconds,
  'status': _$CallStatusEnumMap[instance.status]!,
  'recordingPath': instance.recordingPath,
  'analysisResults': instance.analysisResults,
  'isScamSuspected': instance.isScamSuspected,
  'scamConfidence': instance.scamConfidence,
};

const _$CallStatusEnumMap = {
  CallStatus.incoming: 'incoming',
  CallStatus.active: 'active',
  CallStatus.ended: 'ended',
  CallStatus.missed: 'missed',
  CallStatus.rejected: 'rejected',
};

AnalysisResult _$AnalysisResultFromJson(Map<String, dynamic> json) =>
    AnalysisResult(
      id: json['id'] as String,
      callId: json['callId'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      type: $enumDecode(_$AnalysisTypeEnumMap, json['type']),
      confidence: (json['confidence'] as num).toDouble(),
      details: json['details'] as Map<String, dynamic>,
      isScamIndicator: json['isScamIndicator'] as bool,
    );

Map<String, dynamic> _$AnalysisResultToJson(AnalysisResult instance) =>
    <String, dynamic>{
      'id': instance.id,
      'callId': instance.callId,
      'timestamp': instance.timestamp.toIso8601String(),
      'type': _$AnalysisTypeEnumMap[instance.type]!,
      'confidence': instance.confidence,
      'details': instance.details,
      'isScamIndicator': instance.isScamIndicator,
    };

const _$AnalysisTypeEnumMap = {
  AnalysisType.deepfakeDetection: 'deepfakeDetection',
  AnalysisType.sentimentAnalysis: 'sentimentAnalysis',
  AnalysisType.voiceAuthentication: 'voiceAuthentication',
  AnalysisType.scamPatternDetection: 'scamPatternDetection',
  AnalysisType.stressAnalysis: 'stressAnalysis',
  AnalysisType.emotionDetection: 'emotionDetection',
};
