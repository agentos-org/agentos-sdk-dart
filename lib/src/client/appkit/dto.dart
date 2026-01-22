import 'package:json_annotation/json_annotation.dart';
import '../shared/dto.dart';

part 'dto.g.dart';

@JsonSerializable()
class AppBundle {
  String bundleId;

  AppBundle({required this.bundleId});

  factory AppBundle.fromJson(Map<String, dynamic> json) => _$AppBundleFromJson(json);

  Map<String, dynamic> toJson() => _$AppBundleToJson(this);
}


@JsonSerializable()
class AccessToken {
  String token;

  AccessToken({required this.token});

  factory AccessToken.fromJson(Map<String, dynamic> json) => _$AccessTokenFromJson(json);

  Map<String, dynamic> toJson() => _$AccessTokenToJson(this);
}


class AgentOSEventType {
  static const String welcome = "welcome";
  static const String call = "call";
}


@JsonSerializable()
class AgentOSEvent {
  String agentosEventType; // AgentOSEventType.welcome | AgentOSEventType.call
  String data;

  AgentOSEvent({required this.agentosEventType, required this.data});

  factory AgentOSEvent.fromJson(Map<String, dynamic> json) => _$AgentOSEventFromJson(json);

  Map<String, dynamic> toJson() => _$AgentOSEventToJson(this);
}


@JsonSerializable()
class Welcome {
  String bundleId;

  Welcome({required this.bundleId});

  factory Welcome.fromJson(Map<String, dynamic> json) => _$WelcomeFromJson(json);

  Map<String, dynamic> toJson() => _$WelcomeToJson(this);
}


@JsonSerializable()
class Call {
  String id;
  String from;  // "agentos" | other App bundleId
  List<Content> contentList;

  Call({required this.id, required this.from, required this.contentList});

  factory Call.fromJson(Map<String, dynamic> json) => _$CallFromJson(json);

  Map<String, dynamic> toJson() => _$CallToJson(this);
}


