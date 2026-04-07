import 'package:json_annotation/json_annotation.dart';

part 'dto.g.dart';

@JsonSerializable(explicitToJson: true, includeIfNull: false)
class RagBaseCreateRequest {
  String? baseId;
  String name;
  Map<String, dynamic>? metadata;

  RagBaseCreateRequest({this.baseId, required this.name, this.metadata});

  factory RagBaseCreateRequest.fromJson(Map<String, dynamic> json) =>
      _$RagBaseCreateRequestFromJson(json);

  Map<String, dynamic> toJson() => _$RagBaseCreateRequestToJson(this);
}

@JsonSerializable(explicitToJson: true, includeIfNull: false)
class RagBaseUpdateRequest {
  String baseId;
  String? name;
  Map<String, dynamic>? metadata;

  RagBaseUpdateRequest({required this.baseId, this.name, this.metadata});

  factory RagBaseUpdateRequest.fromJson(Map<String, dynamic> json) =>
      _$RagBaseUpdateRequestFromJson(json);

  Map<String, dynamic> toJson() => _$RagBaseUpdateRequestToJson(this);
}

@JsonSerializable(explicitToJson: true, includeIfNull: false)
class RagMarkdownDocumentInput {
  String documentId;
  String title;
  String markdown;
  Map<String, dynamic>? metadata;

  RagMarkdownDocumentInput({
    required this.documentId,
    required this.title,
    required this.markdown,
    this.metadata,
  });

  factory RagMarkdownDocumentInput.fromJson(Map<String, dynamic> json) =>
      _$RagMarkdownDocumentInputFromJson(json);

  Map<String, dynamic> toJson() => _$RagMarkdownDocumentInputToJson(this);
}

@JsonSerializable(explicitToJson: true, includeIfNull: false)
class RagUpsertDocumentRequest {
  String baseId;
  String documentId;
  String title;
  String markdown;
  Map<String, dynamic>? metadata;
  bool sync;

  RagUpsertDocumentRequest({
    required this.baseId,
    required this.documentId,
    required this.title,
    required this.markdown,
    this.metadata,
    this.sync = true,
  });

  factory RagUpsertDocumentRequest.fromJson(Map<String, dynamic> json) =>
      _$RagUpsertDocumentRequestFromJson(json);

  Map<String, dynamic> toJson() => _$RagUpsertDocumentRequestToJson(this);
}

@JsonSerializable(explicitToJson: true, includeIfNull: false)
class RagUpsertDocumentsRequest {
  String baseId;
  bool sync;
  List<RagMarkdownDocumentInput> documents;

  RagUpsertDocumentsRequest({
    required this.baseId,
    this.sync = true,
    required this.documents,
  });

  factory RagUpsertDocumentsRequest.fromJson(Map<String, dynamic> json) =>
      _$RagUpsertDocumentsRequestFromJson(json);

  Map<String, dynamic> toJson() => _$RagUpsertDocumentsRequestToJson(this);
}

@JsonSerializable(explicitToJson: true, includeIfNull: false)
class RagQueryRequest {
  String baseId;
  String query;
  int? limit;
  int? candidateLimit;

  RagQueryRequest({
    required this.baseId,
    required this.query,
    this.limit,
    this.candidateLimit,
  });

  factory RagQueryRequest.fromJson(Map<String, dynamic> json) =>
      _$RagQueryRequestFromJson(json);

  Map<String, dynamic> toJson() => _$RagQueryRequestToJson(this);
}

@JsonSerializable(explicitToJson: true, includeIfNull: false)
class RagBase {
  String id;
  String name;
  String docsName;
  String docsId;
  Map<String, dynamic>? metadata;
  DateTime createdAt;
  DateTime updatedAt;

  RagBase({
    required this.id,
    required this.name,
    required this.docsName,
    required this.docsId,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RagBase.fromJson(Map<String, dynamic> json) =>
      _$RagBaseFromJson(json);

  Map<String, dynamic> toJson() => _$RagBaseToJson(this);
}

@JsonSerializable(explicitToJson: true, includeIfNull: false)
class RagBaseListItem {
  String id;
  String name;
  DateTime createdAt;
  DateTime updatedAt;

  RagBaseListItem({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RagBaseListItem.fromJson(Map<String, dynamic> json) =>
      _$RagBaseListItemFromJson(json);

  Map<String, dynamic> toJson() => _$RagBaseListItemToJson(this);
}

@JsonSerializable(explicitToJson: true, includeIfNull: false)
class RagDocument {
  String id;
  String baseId;
  String title;
  String markdown;
  String contentHash;
  Map<String, dynamic>? metadata;
  DateTime createdAt;
  DateTime updatedAt;
  DateTime? indexedAt;
  String syncStatus;

  RagDocument({
    required this.id,
    required this.baseId,
    required this.title,
    required this.markdown,
    required this.contentHash,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
    this.indexedAt,
    required this.syncStatus,
  });

  factory RagDocument.fromJson(Map<String, dynamic> json) =>
      _$RagDocumentFromJson(json);

  Map<String, dynamic> toJson() => _$RagDocumentToJson(this);
}

@JsonSerializable(explicitToJson: true, includeIfNull: false)
class RagDocumentListItem {
  String id;
  String baseId;
  String title;
  DateTime updatedAt;
  DateTime? indexedAt;
  String syncStatus;

  RagDocumentListItem({
    required this.id,
    required this.baseId,
    required this.title,
    required this.updatedAt,
    this.indexedAt,
    required this.syncStatus,
  });

  factory RagDocumentListItem.fromJson(Map<String, dynamic> json) =>
      _$RagDocumentListItemFromJson(json);

  Map<String, dynamic> toJson() => _$RagDocumentListItemToJson(this);
}

@JsonSerializable(explicitToJson: true, includeIfNull: false)
class RagDocumentSyncResult {
  String baseId;
  String documentId;
  String syncStatus;
  int keptCount;
  int updatedCount;
  int insertedCount;
  int deletedCount;
  DateTime syncedAt;

  RagDocumentSyncResult({
    required this.baseId,
    required this.documentId,
    required this.syncStatus,
    required this.keptCount,
    required this.updatedCount,
    required this.insertedCount,
    required this.deletedCount,
    required this.syncedAt,
  });

  factory RagDocumentSyncResult.fromJson(Map<String, dynamic> json) =>
      _$RagDocumentSyncResultFromJson(json);

  Map<String, dynamic> toJson() => _$RagDocumentSyncResultToJson(this);
}

@JsonSerializable(explicitToJson: true, includeIfNull: false)
class RagBatchItemResult {
  String baseId;
  String documentId;
  String status;
  String syncStatus;
  String? message;

  RagBatchItemResult({
    required this.baseId,
    required this.documentId,
    required this.status,
    required this.syncStatus,
    this.message,
  });

  factory RagBatchItemResult.fromJson(Map<String, dynamic> json) =>
      _$RagBatchItemResultFromJson(json);

  Map<String, dynamic> toJson() => _$RagBatchItemResultToJson(this);
}

@JsonSerializable(explicitToJson: true, includeIfNull: false)
class RagBatchResult {
  int totalCount;
  int successCount;
  int failedCount;
  int skippedCount;
  DateTime processedAt;
  List<RagBatchItemResult> items;

  RagBatchResult({
    required this.totalCount,
    required this.successCount,
    required this.failedCount,
    required this.skippedCount,
    required this.processedAt,
    required this.items,
  });

  factory RagBatchResult.fromJson(Map<String, dynamic> json) =>
      _$RagBatchResultFromJson(json);

  Map<String, dynamic> toJson() => _$RagBatchResultToJson(this);
}

@JsonSerializable(explicitToJson: true, includeIfNull: false)
class RagSegmentHit {
  String segmentId;
  double score;
  String text;
  String headingPath;

  RagSegmentHit({
    required this.segmentId,
    required this.score,
    required this.text,
    required this.headingPath,
  });

  factory RagSegmentHit.fromJson(Map<String, dynamic> json) =>
      _$RagSegmentHitFromJson(json);

  Map<String, dynamic> toJson() => _$RagSegmentHitToJson(this);
}

@JsonSerializable(explicitToJson: true, includeIfNull: false)
class RagDocumentHit {
  String documentId;
  String title;
  double score;
  String snippet;
  List<RagSegmentHit> segments;

  RagDocumentHit({
    required this.documentId,
    required this.title,
    required this.score,
    required this.snippet,
    required this.segments,
  });

  factory RagDocumentHit.fromJson(Map<String, dynamic> json) =>
      _$RagDocumentHitFromJson(json);

  Map<String, dynamic> toJson() => _$RagDocumentHitToJson(this);
}

@JsonSerializable(explicitToJson: true, includeIfNull: false)
class RagQueryResult {
  String baseId;
  String query;
  List<RagDocumentHit> hits;

  RagQueryResult({
    required this.baseId,
    required this.query,
    required this.hits,
  });

  factory RagQueryResult.fromJson(Map<String, dynamic> json) =>
      _$RagQueryResultFromJson(json);

  Map<String, dynamic> toJson() => _$RagQueryResultToJson(this);
}

@JsonSerializable(includeIfNull: false)
class RagDeleteBaseResult {
  bool deleted;
  String baseId;

  RagDeleteBaseResult({required this.deleted, required this.baseId});

  factory RagDeleteBaseResult.fromJson(Map<String, dynamic> json) =>
      _$RagDeleteBaseResultFromJson(json);

  Map<String, dynamic> toJson() => _$RagDeleteBaseResultToJson(this);
}

@JsonSerializable(includeIfNull: false)
class RagDeleteDocumentResult {
  bool deleted;
  String baseId;
  String documentId;

  RagDeleteDocumentResult({
    required this.deleted,
    required this.baseId,
    required this.documentId,
  });

  factory RagDeleteDocumentResult.fromJson(Map<String, dynamic> json) =>
      _$RagDeleteDocumentResultFromJson(json);

  Map<String, dynamic> toJson() => _$RagDeleteDocumentResultToJson(this);
}
