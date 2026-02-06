// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

IntentKitSubmitRawRequest _$IntentKitSubmitRawRequestFromJson(
  Map<String, dynamic> json,
) => IntentKitSubmitRawRequest(
  source: json['source'] as String? ?? 'api',
  content: (json['content'] as List<dynamic>)
      .map((e) => Content.fromJson(e as Map<String, dynamic>))
      .toList(),
  data: json['data'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$IntentKitSubmitRawRequestToJson(
  IntentKitSubmitRawRequest instance,
) => <String, dynamic>{
  'source': instance.source,
  'content': instance.content.map((e) => e.toJson()).toList(),
  'data': ?instance.data,
};

IntentCandidate _$IntentCandidateFromJson(Map<String, dynamic> json) =>
    IntentCandidate(
      action: json['action'] as String,
      payload: json['payload'] as Map<String, dynamic>,
      confidence: (json['confidence'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$IntentCandidateToJson(IntentCandidate instance) =>
    <String, dynamic>{
      'action': instance.action,
      'payload': instance.payload,
      'confidence': ?instance.confidence,
    };

IntentKitSubmitIntentRequest _$IntentKitSubmitIntentRequestFromJson(
  Map<String, dynamic> json,
) => IntentKitSubmitIntentRequest(
  source: json['source'] as String? ?? 'api',
  intent: IntentCandidate.fromJson(json['intent'] as Map<String, dynamic>),
);

Map<String, dynamic> _$IntentKitSubmitIntentRequestToJson(
  IntentKitSubmitIntentRequest instance,
) => <String, dynamic>{
  'source': instance.source,
  'intent': instance.intent.toJson(),
};

IntentKitConfirmJobRequest _$IntentKitConfirmJobRequestFromJson(
  Map<String, dynamic> json,
) => IntentKitConfirmJobRequest(
  jobId: json['jobId'] as String,
  confirmed: json['confirmed'] as bool,
);

Map<String, dynamic> _$IntentKitConfirmJobRequestToJson(
  IntentKitConfirmJobRequest instance,
) => <String, dynamic>{
  'jobId': instance.jobId,
  'confirmed': instance.confirmed,
};

IntentKitSuggestNextActionRequest _$IntentKitSuggestNextActionRequestFromJson(
  Map<String, dynamic> json,
) => IntentKitSuggestNextActionRequest(
  source: json['source'] as String? ?? 'api',
  allowedActions: (json['allowedActions'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  memoryLimit: (json['memoryLimit'] as num?)?.toInt(),
);

Map<String, dynamic> _$IntentKitSuggestNextActionRequestToJson(
  IntentKitSuggestNextActionRequest instance,
) => <String, dynamic>{
  'source': instance.source,
  'allowedActions': ?instance.allowedActions,
  'memoryLimit': ?instance.memoryLimit,
};

IntentKitJobHandle _$IntentKitJobHandleFromJson(Map<String, dynamic> json) =>
    IntentKitJobHandle(
      jobId: json['jobId'] as String,
      status: json['status'] as String,
    );

Map<String, dynamic> _$IntentKitJobHandleToJson(IntentKitJobHandle instance) =>
    <String, dynamic>{'jobId': instance.jobId, 'status': instance.status};

IntentKitSuggestNextActionResponse _$IntentKitSuggestNextActionResponseFromJson(
  Map<String, dynamic> json,
) => IntentKitSuggestNextActionResponse(
  candidates: (json['candidates'] as List<dynamic>)
      .map((e) => IntentCandidate.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$IntentKitSuggestNextActionResponseToJson(
  IntentKitSuggestNextActionResponse instance,
) => <String, dynamic>{
  'candidates': instance.candidates.map((e) => e.toJson()).toList(),
};
