import 'package:json_annotation/json_annotation.dart';

import '../shared/dto.dart';

part 'dto.g.dart';

@JsonSerializable(explicitToJson: true, includeIfNull: false)
class IntentKitSubmitRawRequest {
  String source;
  List<Content> content;
  Map<String, dynamic>? data;

  IntentKitSubmitRawRequest({
    this.source = 'api',
    required this.content,
    this.data,
  });

  factory IntentKitSubmitRawRequest.fromJson(Map<String, dynamic> json) =>
      _$IntentKitSubmitRawRequestFromJson(json);

  Map<String, dynamic> toJson() => _$IntentKitSubmitRawRequestToJson(this);
}

@JsonSerializable(explicitToJson: true, includeIfNull: false)
class IntentCandidate {
  String action;
  Map<String, dynamic> payload;
  double? confidence;

  IntentCandidate({
    required this.action,
    required this.payload,
    this.confidence,
  });

  factory IntentCandidate.fromJson(Map<String, dynamic> json) =>
      _$IntentCandidateFromJson(json);

  Map<String, dynamic> toJson() => _$IntentCandidateToJson(this);
}

@JsonSerializable(explicitToJson: true, includeIfNull: false)
class IntentKitSubmitIntentRequest {
  String source;
  IntentCandidate intent;

  IntentKitSubmitIntentRequest({this.source = 'api', required this.intent});

  factory IntentKitSubmitIntentRequest.fromJson(Map<String, dynamic> json) =>
      _$IntentKitSubmitIntentRequestFromJson(json);

  Map<String, dynamic> toJson() => _$IntentKitSubmitIntentRequestToJson(this);
}

@JsonSerializable(explicitToJson: true, includeIfNull: false)
class IntentKitConfirmJobRequest {
  String jobId;
  bool confirmed;

  IntentKitConfirmJobRequest({required this.jobId, required this.confirmed});

  factory IntentKitConfirmJobRequest.fromJson(Map<String, dynamic> json) =>
      _$IntentKitConfirmJobRequestFromJson(json);

  Map<String, dynamic> toJson() => _$IntentKitConfirmJobRequestToJson(this);
}

@JsonSerializable(explicitToJson: true, includeIfNull: false)
class IntentKitSuggestNextActionRequest {
  String source;
  List<String>? allowedActions;
  int? memoryLimit;

  IntentKitSuggestNextActionRequest({
    this.source = 'api',
    this.allowedActions,
    this.memoryLimit,
  });

  factory IntentKitSuggestNextActionRequest.fromJson(
    Map<String, dynamic> json,
  ) => _$IntentKitSuggestNextActionRequestFromJson(json);

  Map<String, dynamic> toJson() =>
      _$IntentKitSuggestNextActionRequestToJson(this);
}

@JsonSerializable(explicitToJson: true, includeIfNull: false)
class IntentKitJobHandle {
  String jobId;
  String status;

  IntentKitJobHandle({required this.jobId, required this.status});

  factory IntentKitJobHandle.fromJson(Map<String, dynamic> json) =>
      _$IntentKitJobHandleFromJson(json);

  Map<String, dynamic> toJson() => _$IntentKitJobHandleToJson(this);
}

@JsonSerializable(explicitToJson: true, includeIfNull: false)
class IntentKitSuggestNextActionResponse {
  List<IntentCandidate> candidates;

  IntentKitSuggestNextActionResponse({required this.candidates});

  factory IntentKitSuggestNextActionResponse.fromJson(
    Map<String, dynamic> json,
  ) => _$IntentKitSuggestNextActionResponseFromJson(json);

  Map<String, dynamic> toJson() =>
      _$IntentKitSuggestNextActionResponseToJson(this);
}
