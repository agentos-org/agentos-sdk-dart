import 'package:json_annotation/json_annotation.dart';

part 'dto.g.dart';

@JsonSerializable(includeIfNull: false, explicitToJson: true)
class AppBundle {
  String bundleId;
  String? appGroupId;
  List<OpenToolServerDeclaration> opentoolServers;

  AppBundle({
    required this.bundleId,
    this.appGroupId,
    this.opentoolServers = const [],
  });

  factory AppBundle.fromJson(Map<String, dynamic> json) =>
      _$AppBundleFromJson(json);

  Map<String, dynamic> toJson() => _$AppBundleToJson(this);
}

@JsonSerializable(includeIfNull: false, explicitToJson: true)
class AccessToken {
  String token;
  String? bundleId;
  String? appGroupId;
  List<OpenToolServerRegistration> opentoolServers;

  AccessToken({
    required this.token,
    this.bundleId,
    this.appGroupId,
    this.opentoolServers = const [],
  });

  factory AccessToken.fromJson(Map<String, dynamic> json) =>
      _$AccessTokenFromJson(json);

  Map<String, dynamic> toJson() => _$AccessTokenToJson(this);
}

class AgentOSEventType {
  static const String welcome = 'welcome';
  static const String error = 'error';
  static const String appEvent = 'appEvent';
}

@JsonSerializable()
class AgentOSEvent {
  String? id;
  String agentosEventType;
  String data;

  AgentOSEvent({this.id, required this.agentosEventType, required this.data});

  factory AgentOSEvent.fromJson(Map<String, dynamic> json) =>
      _$AgentOSEventFromJson(json);

  Map<String, dynamic> toJson() => _$AgentOSEventToJson(this);
}

@JsonSerializable()
class Welcome {
  String bundleId;
  String? appGroupId;

  Welcome({required this.bundleId, this.appGroupId});

  factory Welcome.fromJson(Map<String, dynamic> json) =>
      _$WelcomeFromJson(json);

  Map<String, dynamic> toJson() => _$WelcomeToJson(this);
}

@JsonSerializable()
class AppKitError {
  String error;

  AppKitError({required this.error});

  factory AppKitError.fromJson(Map<String, dynamic> json) =>
      _$AppKitErrorFromJson(json);

  Map<String, dynamic> toJson() => _$AppKitErrorToJson(this);
}

/// Declares one native OpenTool server dependency during AppKit registration.
@JsonSerializable(includeIfNull: false)
class OpenToolServerDeclaration {
  const OpenToolServerDeclaration({required this.ref, required this.name});

  final String ref;
  final String name;

  factory OpenToolServerDeclaration.fromJson(Map<String, dynamic> json) =>
      _$OpenToolServerDeclarationFromJson(json);

  Map<String, dynamic> toJson() => _$OpenToolServerDeclarationToJson(this);
}

/// Identifies the native OpenTool server resolved by the gateway.
@JsonSerializable(includeIfNull: false)
class OpenToolResolvedServer {
  const OpenToolResolvedServer({
    required this.repo,
    required this.name,
    required this.tag,
  });

  /// The OpenTool V2 namespace.
  ///
  /// [repo] is retained as the stored field for source compatibility with
  /// SDK clients built against the legacy AppKit response shape.
  String get namespace => repo;

  @JsonKey(name: 'namespace', readValue: _readOpenToolNamespace)
  final String repo;
  final String name;

  /// The OpenTool V2 server version.
  ///
  /// [tag] is retained as the stored field for source compatibility with SDK
  /// clients built against the legacy AppKit response shape.
  String get version => tag;

  @JsonKey(name: 'version', readValue: _readOpenToolVersion)
  final String tag;

  factory OpenToolResolvedServer.fromJson(Map<String, dynamic> json) =>
      _$OpenToolResolvedServerFromJson(json);

  Map<String, dynamic> toJson() => _$OpenToolResolvedServerToJson(this);
}

Object? _readOpenToolNamespace(Map<dynamic, dynamic> json, String _) =>
    json['namespace'] ?? json['repo'];

Object? _readOpenToolVersion(Map<dynamic, dynamic> json, String _) =>
    json['version'] ?? json['tag'];

/// Status values returned for declared OpenTool servers.
class OpenToolRegistrationStatus {
  static const String running = 'running';
  static const String starting = 'starting';
  static const String notFound = 'notFound';
}

/// Result for one declared OpenTool server in the registration response.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class OpenToolServerRegistration {
  const OpenToolServerRegistration({
    required this.ref,
    required this.status,
    this.name,
    this.server,
    this.id,
  });

  final String ref;
  final String status;
  final String? name;
  final OpenToolResolvedServer? server;
  final String? id;

  factory OpenToolServerRegistration.fromJson(Map<String, dynamic> json) =>
      _$OpenToolServerRegistrationFromJson(json);

  Map<String, dynamic> toJson() => _$OpenToolServerRegistrationToJson(this);
}

/// Known AppKit business-event types.
class AppEventType {
  static const String toolkitProvisionSucceeded = 'toolkit.provision.succeeded';
  static const String toolkitProvisionFailed = 'toolkit.provision.failed';
  static const String appCommandRequested = 'app.command.requested';
}

/// Generic AppKit business-event envelope delivered through `subscribe`.
@JsonSerializable(explicitToJson: true)
class AppEvent {
  const AppEvent({
    required this.version,
    required this.id,
    required this.type,
    required this.source,
    required this.time,
    required this.subject,
    required this.data,
  });

  final int version;
  final String id;
  final String type;
  final String source;
  final DateTime time;
  final String subject;
  final Map<String, dynamic> data;

  factory AppEvent.fromJson(Map<String, dynamic> json) =>
      _$AppEventFromJson(json);

  Map<String, dynamic> toJson() => _$AppEventToJson(this);

  /// Returns typed success data for `toolkit.provision.succeeded`, if
  /// applicable.
  OpenToolProvisionSuccess? get openToolProvisionSuccess {
    if (type != AppEventType.toolkitProvisionSucceeded) {
      return null;
    }
    return OpenToolProvisionSuccess.fromJson(data);
  }

  /// Returns typed failure data for `toolkit.provision.failed`, if applicable.
  OpenToolProvisionFailure? get openToolProvisionFailure {
    if (type != AppEventType.toolkitProvisionFailed) {
      return null;
    }
    return OpenToolProvisionFailure.fromJson(data);
  }
}

/// Details for an asynchronously completed OpenTool provisioning operation.
@JsonSerializable(explicitToJson: true)
class OpenToolProvisionSuccess {
  const OpenToolProvisionSuccess({
    required this.ref,
    required this.name,
    required this.status,
    required this.server,
    required this.id,
  });

  final String ref;
  final String name;
  final String status;
  final OpenToolResolvedServer server;
  final String id;

  factory OpenToolProvisionSuccess.fromJson(Map<String, dynamic> json) =>
      _$OpenToolProvisionSuccessFromJson(json);

  Map<String, dynamic> toJson() => _$OpenToolProvisionSuccessToJson(this);
}

/// Details for an asynchronous OpenTool provisioning failure.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class OpenToolProvisionFailure {
  const OpenToolProvisionFailure({
    required this.ref,
    required this.name,
    required this.status,
    required this.error,
    this.server,
  });

  final String ref;
  final String name;
  final String status;
  final OpenToolResolvedServer? server;
  final AppEventError error;

  factory OpenToolProvisionFailure.fromJson(Map<String, dynamic> json) =>
      _$OpenToolProvisionFailureFromJson(json);

  Map<String, dynamic> toJson() => _$OpenToolProvisionFailureToJson(this);
}

/// Machine-readable error details embedded in an AppKit business event.
@JsonSerializable()
class AppEventError {
  const AppEventError({required this.code, required this.message});

  final String code;
  final String message;

  factory AppEventError.fromJson(Map<String, dynamic> json) =>
      _$AppEventErrorFromJson(json);

  Map<String, dynamic> toJson() => _$AppEventErrorToJson(this);
}
