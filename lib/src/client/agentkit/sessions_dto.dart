import 'package:json_annotation/json_annotation.dart';
import 'messages_dto.dart';

part 'sessions_dto.g.dart';

@JsonSerializable()
class Session {
  String sessionId;

  Session({required this.sessionId});

  factory Session.fromJson(Map<String, dynamic> json) =>
      _$SessionFromJson(json);

  Map<String, dynamic> toJson() => _$SessionToJson(this);
}

@JsonSerializable(explicitToJson: true)
class SessionTask {
  String sessionId;
  String? taskId;

  SessionTask({required this.sessionId, this.taskId});

  factory SessionTask.fromJson(Map<String, dynamic> json) =>
      _$SessionTaskFromJson(json);

  Map<String, dynamic> toJson() => _$SessionTaskToJson(this);
}

@JsonSerializable(explicitToJson: true, includeIfNull: false)
class SessionAgentMessage {
  String sessionId;
  AgentMessage agentMessage;
  SessionAgentMessage({required this.sessionId, required this.agentMessage});

  factory SessionAgentMessage.fromJson(Map<String, dynamic> json) =>
      _$SessionAgentMessageFromJson(json);

  Map<String, dynamic> toJson() => _$SessionAgentMessageToJson(this);
}
