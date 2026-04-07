// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RagBaseCreateRequest _$RagBaseCreateRequestFromJson(
  Map<String, dynamic> json,
) => RagBaseCreateRequest(
  baseId: json['baseId'] as String?,
  name: json['name'] as String,
  metadata: json['metadata'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$RagBaseCreateRequestToJson(
  RagBaseCreateRequest instance,
) => <String, dynamic>{
  'baseId': ?instance.baseId,
  'name': instance.name,
  'metadata': ?instance.metadata,
};

RagBaseUpdateRequest _$RagBaseUpdateRequestFromJson(
  Map<String, dynamic> json,
) => RagBaseUpdateRequest(
  baseId: json['baseId'] as String,
  name: json['name'] as String?,
  metadata: json['metadata'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$RagBaseUpdateRequestToJson(
  RagBaseUpdateRequest instance,
) => <String, dynamic>{
  'baseId': instance.baseId,
  'name': ?instance.name,
  'metadata': ?instance.metadata,
};

RagMarkdownDocumentInput _$RagMarkdownDocumentInputFromJson(
  Map<String, dynamic> json,
) => RagMarkdownDocumentInput(
  documentId: json['documentId'] as String,
  title: json['title'] as String,
  markdown: json['markdown'] as String,
  metadata: json['metadata'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$RagMarkdownDocumentInputToJson(
  RagMarkdownDocumentInput instance,
) => <String, dynamic>{
  'documentId': instance.documentId,
  'title': instance.title,
  'markdown': instance.markdown,
  'metadata': ?instance.metadata,
};

RagUpsertDocumentRequest _$RagUpsertDocumentRequestFromJson(
  Map<String, dynamic> json,
) => RagUpsertDocumentRequest(
  baseId: json['baseId'] as String,
  documentId: json['documentId'] as String,
  title: json['title'] as String,
  markdown: json['markdown'] as String,
  metadata: json['metadata'] as Map<String, dynamic>?,
  sync: json['sync'] as bool? ?? true,
);

Map<String, dynamic> _$RagUpsertDocumentRequestToJson(
  RagUpsertDocumentRequest instance,
) => <String, dynamic>{
  'baseId': instance.baseId,
  'documentId': instance.documentId,
  'title': instance.title,
  'markdown': instance.markdown,
  'metadata': ?instance.metadata,
  'sync': instance.sync,
};

RagUpsertDocumentsRequest _$RagUpsertDocumentsRequestFromJson(
  Map<String, dynamic> json,
) => RagUpsertDocumentsRequest(
  baseId: json['baseId'] as String,
  sync: json['sync'] as bool? ?? true,
  documents: (json['documents'] as List<dynamic>)
      .map((e) => RagMarkdownDocumentInput.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$RagUpsertDocumentsRequestToJson(
  RagUpsertDocumentsRequest instance,
) => <String, dynamic>{
  'baseId': instance.baseId,
  'sync': instance.sync,
  'documents': instance.documents.map((e) => e.toJson()).toList(),
};

RagQueryRequest _$RagQueryRequestFromJson(Map<String, dynamic> json) =>
    RagQueryRequest(
      baseId: json['baseId'] as String,
      query: json['query'] as String,
      limit: (json['limit'] as num?)?.toInt(),
      candidateLimit: (json['candidateLimit'] as num?)?.toInt(),
    );

Map<String, dynamic> _$RagQueryRequestToJson(RagQueryRequest instance) =>
    <String, dynamic>{
      'baseId': instance.baseId,
      'query': instance.query,
      'limit': ?instance.limit,
      'candidateLimit': ?instance.candidateLimit,
    };

RagBase _$RagBaseFromJson(Map<String, dynamic> json) => RagBase(
  id: json['id'] as String,
  name: json['name'] as String,
  docsName: json['docsName'] as String,
  docsId: json['docsId'] as String,
  metadata: json['metadata'] as Map<String, dynamic>?,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$RagBaseToJson(RagBase instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'docsName': instance.docsName,
  'docsId': instance.docsId,
  'metadata': ?instance.metadata,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
};

RagBaseListItem _$RagBaseListItemFromJson(Map<String, dynamic> json) =>
    RagBaseListItem(
      id: json['id'] as String,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$RagBaseListItemToJson(RagBaseListItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };

RagDocument _$RagDocumentFromJson(Map<String, dynamic> json) => RagDocument(
  id: json['id'] as String,
  baseId: json['baseId'] as String,
  title: json['title'] as String,
  markdown: json['markdown'] as String,
  contentHash: json['contentHash'] as String,
  metadata: json['metadata'] as Map<String, dynamic>?,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
  indexedAt: json['indexedAt'] == null
      ? null
      : DateTime.parse(json['indexedAt'] as String),
  syncStatus: json['syncStatus'] as String,
);

Map<String, dynamic> _$RagDocumentToJson(RagDocument instance) =>
    <String, dynamic>{
      'id': instance.id,
      'baseId': instance.baseId,
      'title': instance.title,
      'markdown': instance.markdown,
      'contentHash': instance.contentHash,
      'metadata': ?instance.metadata,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'indexedAt': ?instance.indexedAt?.toIso8601String(),
      'syncStatus': instance.syncStatus,
    };

RagDocumentListItem _$RagDocumentListItemFromJson(Map<String, dynamic> json) =>
    RagDocumentListItem(
      id: json['id'] as String,
      baseId: json['baseId'] as String,
      title: json['title'] as String,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      indexedAt: json['indexedAt'] == null
          ? null
          : DateTime.parse(json['indexedAt'] as String),
      syncStatus: json['syncStatus'] as String,
    );

Map<String, dynamic> _$RagDocumentListItemToJson(
  RagDocumentListItem instance,
) => <String, dynamic>{
  'id': instance.id,
  'baseId': instance.baseId,
  'title': instance.title,
  'updatedAt': instance.updatedAt.toIso8601String(),
  'indexedAt': ?instance.indexedAt?.toIso8601String(),
  'syncStatus': instance.syncStatus,
};

RagDocumentSyncResult _$RagDocumentSyncResultFromJson(
  Map<String, dynamic> json,
) => RagDocumentSyncResult(
  baseId: json['baseId'] as String,
  documentId: json['documentId'] as String,
  syncStatus: json['syncStatus'] as String,
  keptCount: (json['keptCount'] as num).toInt(),
  updatedCount: (json['updatedCount'] as num).toInt(),
  insertedCount: (json['insertedCount'] as num).toInt(),
  deletedCount: (json['deletedCount'] as num).toInt(),
  syncedAt: DateTime.parse(json['syncedAt'] as String),
);

Map<String, dynamic> _$RagDocumentSyncResultToJson(
  RagDocumentSyncResult instance,
) => <String, dynamic>{
  'baseId': instance.baseId,
  'documentId': instance.documentId,
  'syncStatus': instance.syncStatus,
  'keptCount': instance.keptCount,
  'updatedCount': instance.updatedCount,
  'insertedCount': instance.insertedCount,
  'deletedCount': instance.deletedCount,
  'syncedAt': instance.syncedAt.toIso8601String(),
};

RagBatchItemResult _$RagBatchItemResultFromJson(Map<String, dynamic> json) =>
    RagBatchItemResult(
      baseId: json['baseId'] as String,
      documentId: json['documentId'] as String,
      status: json['status'] as String,
      syncStatus: json['syncStatus'] as String,
      message: json['message'] as String?,
    );

Map<String, dynamic> _$RagBatchItemResultToJson(RagBatchItemResult instance) =>
    <String, dynamic>{
      'baseId': instance.baseId,
      'documentId': instance.documentId,
      'status': instance.status,
      'syncStatus': instance.syncStatus,
      'message': ?instance.message,
    };

RagBatchResult _$RagBatchResultFromJson(Map<String, dynamic> json) =>
    RagBatchResult(
      totalCount: (json['totalCount'] as num).toInt(),
      successCount: (json['successCount'] as num).toInt(),
      failedCount: (json['failedCount'] as num).toInt(),
      skippedCount: (json['skippedCount'] as num).toInt(),
      processedAt: DateTime.parse(json['processedAt'] as String),
      items: (json['items'] as List<dynamic>)
          .map((e) => RagBatchItemResult.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$RagBatchResultToJson(RagBatchResult instance) =>
    <String, dynamic>{
      'totalCount': instance.totalCount,
      'successCount': instance.successCount,
      'failedCount': instance.failedCount,
      'skippedCount': instance.skippedCount,
      'processedAt': instance.processedAt.toIso8601String(),
      'items': instance.items.map((e) => e.toJson()).toList(),
    };

RagSegmentHit _$RagSegmentHitFromJson(Map<String, dynamic> json) =>
    RagSegmentHit(
      segmentId: json['segmentId'] as String,
      score: (json['score'] as num).toDouble(),
      text: json['text'] as String,
      headingPath: json['headingPath'] as String,
    );

Map<String, dynamic> _$RagSegmentHitToJson(RagSegmentHit instance) =>
    <String, dynamic>{
      'segmentId': instance.segmentId,
      'score': instance.score,
      'text': instance.text,
      'headingPath': instance.headingPath,
    };

RagDocumentHit _$RagDocumentHitFromJson(Map<String, dynamic> json) =>
    RagDocumentHit(
      documentId: json['documentId'] as String,
      title: json['title'] as String,
      score: (json['score'] as num).toDouble(),
      snippet: json['snippet'] as String,
      segments: (json['segments'] as List<dynamic>)
          .map((e) => RagSegmentHit.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$RagDocumentHitToJson(RagDocumentHit instance) =>
    <String, dynamic>{
      'documentId': instance.documentId,
      'title': instance.title,
      'score': instance.score,
      'snippet': instance.snippet,
      'segments': instance.segments.map((e) => e.toJson()).toList(),
    };

RagQueryResult _$RagQueryResultFromJson(Map<String, dynamic> json) =>
    RagQueryResult(
      baseId: json['baseId'] as String,
      query: json['query'] as String,
      hits: (json['hits'] as List<dynamic>)
          .map((e) => RagDocumentHit.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$RagQueryResultToJson(RagQueryResult instance) =>
    <String, dynamic>{
      'baseId': instance.baseId,
      'query': instance.query,
      'hits': instance.hits.map((e) => e.toJson()).toList(),
    };

RagDeleteBaseResult _$RagDeleteBaseResultFromJson(Map<String, dynamic> json) =>
    RagDeleteBaseResult(
      deleted: json['deleted'] as bool,
      baseId: json['baseId'] as String,
    );

Map<String, dynamic> _$RagDeleteBaseResultToJson(
  RagDeleteBaseResult instance,
) => <String, dynamic>{'deleted': instance.deleted, 'baseId': instance.baseId};

RagDeleteDocumentResult _$RagDeleteDocumentResultFromJson(
  Map<String, dynamic> json,
) => RagDeleteDocumentResult(
  deleted: json['deleted'] as bool,
  baseId: json['baseId'] as String,
  documentId: json['documentId'] as String,
);

Map<String, dynamic> _$RagDeleteDocumentResultToJson(
  RagDeleteDocumentResult instance,
) => <String, dynamic>{
  'deleted': instance.deleted,
  'baseId': instance.baseId,
  'documentId': instance.documentId,
};
