import 'package:json_annotation/json_annotation.dart';
import '../shared/dto.dart';

part 'dto.g.dart';

@JsonSerializable(includeIfNull: false)
class AppBundle {
  String bundleId;
  String? appGroupId;

  AppBundle({required this.bundleId, this.appGroupId});

  factory AppBundle.fromJson(Map<String, dynamic> json) =>
      _$AppBundleFromJson(json);

  Map<String, dynamic> toJson() => _$AppBundleToJson(this);
}

@JsonSerializable(includeIfNull: false)
class AccessToken {
  String token;
  String? bundleId;
  String? appGroupId;

  AccessToken({required this.token, this.bundleId, this.appGroupId});

  factory AccessToken.fromJson(Map<String, dynamic> json) =>
      _$AccessTokenFromJson(json);

  Map<String, dynamic> toJson() => _$AccessTokenToJson(this);
}

class AgentOSEventType {
  static const String welcome = "welcome";
  static const String error = "error";
  static const String callApp = "callApp";
}

@JsonSerializable()
class AgentOSEvent {
  String
  agentosEventType; // AgentOSEventType.welcome | AgentOSEventType.callApp
  String data;

  AgentOSEvent({required this.agentosEventType, required this.data});

  factory AgentOSEvent.fromJson(Map<String, dynamic> json) =>
      _$AgentOSEventFromJson(json);

  Map<String, dynamic> toJson() => _$AgentOSEventToJson(this);
}

@JsonSerializable()
class Welcome {
  String bundleId;

  Welcome({required this.bundleId});

  factory Welcome.fromJson(Map<String, dynamic> json) =>
      _$WelcomeFromJson(json);

  Map<String, dynamic> toJson() => _$WelcomeToJson(this);
}

class Call {
  String bundleId;
  List<Content> contentList;

  Call({required this.bundleId, required this.contentList});

  factory Call.fromJson(Map<String, dynamic> json) {
    final dynamic rawContentList = json['contentList'];
    final List<dynamic> items = rawContentList is List
        ? rawContentList
        : const <dynamic>[];
    return Call(
      bundleId: (json['bundleId'] ?? '').toString(),
      contentList: items
          .whereType<Map>()
          .map((item) => Content.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'bundleId': bundleId,
    'contentList': contentList.map((item) => item.toJson()).toList(),
  };
}

typedef CallAppEvent = Call;

@JsonSerializable()
class AppKitError {
  String error;

  AppKitError({required this.error});

  factory AppKitError.fromJson(Map<String, dynamic> json) =>
      _$AppKitErrorFromJson(json);

  Map<String, dynamic> toJson() => _$AppKitErrorToJson(this);
}
