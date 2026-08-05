import 'package:json_annotation/json_annotation.dart';

part 'dto.g.dart';

enum AuthRequestStatus { pending, granted, denied, timeout }

enum TokenValidationResult { valid, invalidToken, authExpired, tokenRevoked }

@JsonSerializable(includeIfNull: false)
class AuthorizeRequest {
  List<String>? scopes;
  String? appName;

  AuthorizeRequest({this.scopes, this.appName});

  factory AuthorizeRequest.fromJson(Map<String, dynamic> json) =>
      _$AuthorizeRequestFromJson(json);

  Map<String, dynamic> toJson() => _$AuthorizeRequestToJson(this);
}

@JsonSerializable(includeIfNull: false)
class AuthorizeResponse {
  String requestId;
  AuthRequestStatus status;
  String? authCode;

  AuthorizeResponse({
    required this.requestId,
    required this.status,
    this.authCode,
  });

  factory AuthorizeResponse.fromJson(Map<String, dynamic> json) =>
      _$AuthorizeResponseFromJson(json);

  Map<String, dynamic> toJson() => _$AuthorizeResponseToJson(this);
}

@JsonSerializable(includeIfNull: false)
class ExchangeTokenRequest {
  String authCode;

  ExchangeTokenRequest({required this.authCode});

  factory ExchangeTokenRequest.fromJson(Map<String, dynamic> json) =>
      _$ExchangeTokenRequestFromJson(json);

  Map<String, dynamic> toJson() => _$ExchangeTokenRequestToJson(this);
}

@JsonSerializable(includeIfNull: false)
class ExchangeTokenResponse {
  String accessToken;
  AuthKitUserInfo userInfo;
  String? userId;

  ExchangeTokenResponse({
    required this.accessToken,
    required this.userInfo,
    this.userId,
  });

  factory ExchangeTokenResponse.fromJson(Map<String, dynamic> json) =>
      _$ExchangeTokenResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ExchangeTokenResponseToJson(this);
}

@JsonSerializable(includeIfNull: false)
class AuthKitUserInfo {
  String? userId;
  String name;
  String avatarUrl;

  AuthKitUserInfo({
    this.userId,
    required this.name,
    required this.avatarUrl,
  });

  factory AuthKitUserInfo.fromJson(Map<String, dynamic> json) =>
      _$AuthKitUserInfoFromJson(json);

  Map<String, dynamic> toJson() => _$AuthKitUserInfoToJson(this);
}

@JsonSerializable(includeIfNull: false)
class RevokeRequest {
  String? bundleId;

  RevokeRequest({this.bundleId});

  factory RevokeRequest.fromJson(Map<String, dynamic> json) =>
      _$RevokeRequestFromJson(json);

  Map<String, dynamic> toJson() => _$RevokeRequestToJson(this);
}

@JsonSerializable(includeIfNull: false)
class RevokeResponse {
  String status;

  RevokeResponse({required this.status});

  factory RevokeResponse.fromJson(Map<String, dynamic> json) =>
      _$RevokeResponseFromJson(json);

  Map<String, dynamic> toJson() => _$RevokeResponseToJson(this);
}
