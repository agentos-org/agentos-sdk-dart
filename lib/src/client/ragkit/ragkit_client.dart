import 'dart:io';

import 'package:dio/dio.dart';

import '../../utils/api_client.dart';
import 'dto.dart';

class RagKitClient {
  RagKitClient({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<RagBase> getBase({
    required String bearerToken,
    required String baseId,
  }) async {
    final response = await _apiClient.dio.get<dynamic>(
      '/ragkit/base',
      queryParameters: <String, dynamic>{'baseId': baseId},
      options: _options(bearerToken),
    );
    return RagBase.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  Future<List<RagBaseListItem>> listBases({
    required String bearerToken,
    int? offset,
    int? limit,
  }) async {
    final response = await _apiClient.dio.get<dynamic>(
      '/ragkit/base/list',
      queryParameters: <String, dynamic>{
        if (offset != null) 'offset': offset,
        if (limit != null) 'limit': limit,
      },
      options: _options(bearerToken),
    );
    final items = response.data as List<dynamic>? ?? const <dynamic>[];
    return items
        .whereType<Map>()
        .map(
          (item) => RagBaseListItem.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  Future<RagBase> createBase({
    required String bearerToken,
    required RagBaseCreateRequest request,
  }) async {
    final response = await _apiClient.dio.post<dynamic>(
      '/ragkit/base/create',
      data: request.toJson(),
      options: _options(bearerToken),
    );
    return RagBase.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  Future<RagBase> updateBase({
    required String bearerToken,
    required RagBaseUpdateRequest request,
  }) async {
    final response = await _apiClient.dio.post<dynamic>(
      '/ragkit/base/update',
      data: request.toJson(),
      options: _options(bearerToken),
    );
    return RagBase.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  Future<RagDeleteBaseResult> deleteBase({
    required String bearerToken,
    required String baseId,
  }) async {
    final response = await _apiClient.dio.post<dynamic>(
      '/ragkit/base/delete',
      data: <String, dynamic>{'baseId': baseId},
      options: _options(bearerToken),
    );
    return RagDeleteBaseResult.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<RagDocument> getDocument({
    required String bearerToken,
    required String baseId,
    required String documentId,
  }) async {
    final response = await _apiClient.dio.get<dynamic>(
      '/ragkit/document',
      queryParameters: <String, dynamic>{
        'baseId': baseId,
        'documentId': documentId,
      },
      options: _options(bearerToken),
    );
    return RagDocument.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<List<RagDocumentListItem>> listDocuments({
    required String bearerToken,
    required String baseId,
    int? offset,
    int? limit,
  }) async {
    final response = await _apiClient.dio.get<dynamic>(
      '/ragkit/document/list',
      queryParameters: <String, dynamic>{
        'baseId': baseId,
        if (offset != null) 'offset': offset,
        if (limit != null) 'limit': limit,
      },
      options: _options(bearerToken),
    );
    final items = response.data as List<dynamic>? ?? const <dynamic>[];
    return items
        .whereType<Map>()
        .map(
          (item) =>
              RagDocumentListItem.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  Future<RagDocument> upsertDocument({
    required String bearerToken,
    required RagUpsertDocumentRequest request,
  }) async {
    final response = await _apiClient.dio.post<dynamic>(
      '/ragkit/document/upsert',
      data: request.toJson(),
      options: _options(bearerToken),
    );
    return RagDocument.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<RagBatchResult> upsertDocuments({
    required String bearerToken,
    required RagUpsertDocumentsRequest request,
  }) async {
    final response = await _apiClient.dio.post<dynamic>(
      '/ragkit/document/upsertBatch',
      data: request.toJson(),
      options: _options(bearerToken),
    );
    return RagBatchResult.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<RagDeleteDocumentResult> deleteDocument({
    required String bearerToken,
    required String baseId,
    required String documentId,
  }) async {
    final response = await _apiClient.dio.post<dynamic>(
      '/ragkit/document/delete',
      data: <String, dynamic>{'baseId': baseId, 'documentId': documentId},
      options: _options(bearerToken),
    );
    return RagDeleteDocumentResult.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<RagDocumentSyncResult> syncDocument({
    required String bearerToken,
    required String baseId,
    required String documentId,
  }) async {
    final response = await _apiClient.dio.post<dynamic>(
      '/ragkit/sync/document',
      data: <String, dynamic>{'baseId': baseId, 'documentId': documentId},
      options: _options(bearerToken),
    );
    return RagDocumentSyncResult.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<RagBatchResult> syncBase({
    required String bearerToken,
    required String baseId,
  }) async {
    final response = await _apiClient.dio.post<dynamic>(
      '/ragkit/sync/base',
      data: <String, dynamic>{'baseId': baseId},
      options: _options(bearerToken),
    );
    return RagBatchResult.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<RagBatchResult> retryFailed({
    required String bearerToken,
    String? baseId,
  }) async {
    final response = await _apiClient.dio.post<dynamic>(
      '/ragkit/sync/retryFailed',
      data: <String, dynamic>{if (baseId != null) 'baseId': baseId},
      options: _options(bearerToken),
    );
    return RagBatchResult.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<RagQueryResult> query({
    required String bearerToken,
    required RagQueryRequest request,
  }) async {
    final response = await _apiClient.dio.post<dynamic>(
      '/ragkit/query',
      data: request.toJson(),
      options: _options(bearerToken),
    );
    return RagQueryResult.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Options _options(String bearerToken) => Options(
    headers: <String, dynamic>{
      HttpHeaders.authorizationHeader: 'Bearer $bearerToken',
    },
  );
}
