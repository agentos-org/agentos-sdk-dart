// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sessions_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Session _$SessionFromJson(Map<String, dynamic> json) =>
    Session(sessionId: json['sessionId'] as String);

Map<String, dynamic> _$SessionToJson(Session instance) => <String, dynamic>{
  'sessionId': instance.sessionId,
};

SessionTask _$SessionTaskFromJson(Map<String, dynamic> json) => SessionTask(
  sessionId: json['sessionId'] as String,
  taskId: json['taskId'] as String?,
);

Map<String, dynamic> _$SessionTaskToJson(SessionTask instance) =>
    <String, dynamic>{
      'sessionId': instance.sessionId,
      'taskId': instance.taskId,
    };

SessionAgentMessage _$SessionAgentMessageFromJson(Map<String, dynamic> json) =>
    SessionAgentMessage(
      sessionId: json['sessionId'] as String,
      agentMessage: AgentMessage.fromJson(
        json['agentMessage'] as Map<String, dynamic>,
      ),
    );

Map<String, dynamic> _$SessionAgentMessageToJson(
  SessionAgentMessage instance,
) => <String, dynamic>{
  'sessionId': instance.sessionId,
  'agentMessage': instance.agentMessage.toJson(),
};
