import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:sse_client_dart/sse_client_dart.dart';

import '../../utils/api_client.dart';
import 'dto.dart';

class TransferKitClient {
  TransferKitClient({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<TransferSession> send({
    required String bearerToken,
    required TransferSendRequest request,
  }) async {
    final response = await _apiClient.dio.post<dynamic>(
      '/transferkit/send',
      data: request.toJson(),
      options: _options(bearerToken),
    );
    return TransferSession.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<List<TransferSession>> listTransfers({
    required String bearerToken,
  }) async {
    final response = await _apiClient.dio.get<dynamic>(
      '/transferkit/transfers',
      options: _options(bearerToken),
    );
    final items = response.data as List<dynamic>? ?? const <dynamic>[];
    return items
        .whereType<Map>()
        .map(
          (item) =>
              TransferSession.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  Future<TransferSession> getStatus({
    required String bearerToken,
    required String transferId,
  }) async {
    final response = await _apiClient.dio.get<dynamic>(
      '/transferkit/transfers/$transferId/status',
      options: _options(bearerToken),
    );
    return TransferSession.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<Stream<TransferSession>> streamProgress({
    required String bearerToken,
    required String transferId,
  }) async {
    final response = await _apiClient.dio.get<ResponseBody>(
      '/transferkit/transfers/$transferId/stream',
      options: Options(
        responseType: ResponseType.stream,
        receiveTimeout: Duration.zero,
        headers: <String, dynamic>{
          HttpHeaders.authorizationHeader: 'Bearer $bearerToken',
        },
      ),
    );
    final body = response.data;
    if (body == null) {
      return const Stream<TransferSession>.empty();
    }
    return body.stream
        .cast<List<int>>()
        .transform(const EventSourceDecoder())
        .where((event) => event.data != null && event.data!.isNotEmpty)
        .map((event) {
          final json = jsonDecode(event.data!) as Map<String, dynamic>;
          return TransferSession.fromJson(json);
        });
  }

  Future<StatusResponse> cancel({
    required String bearerToken,
    required String transferId,
  }) async {
    final response = await _apiClient.dio.post<dynamic>(
      '/transferkit/transfers/$transferId/cancel',
      data: <String, dynamic>{},
      options: _options(bearerToken),
    );
    return StatusResponse.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<StatusResponse> respond({
    required String bearerToken,
    required String transferId,
    required TransferRespondRequest request,
  }) async {
    final response = await _apiClient.dio.post<dynamic>(
      '/transferkit/transfers/$transferId/respond',
      data: request.toJson(),
      options: _options(bearerToken),
    );
    return StatusResponse.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<Stream<IncomingTransferEvent>> receiveStream({
    required String bearerToken,
  }) async {
    final response = await _apiClient.dio.get<ResponseBody>(
      '/transferkit/receive/stream',
      options: Options(
        responseType: ResponseType.stream,
        receiveTimeout: Duration.zero,
        headers: <String, dynamic>{
          HttpHeaders.authorizationHeader: 'Bearer $bearerToken',
        },
      ),
    );
    final body = response.data;
    if (body == null) {
      return const Stream<IncomingTransferEvent>.empty();
    }
    return body.stream
        .cast<List<int>>()
        .transform(const EventSourceDecoder())
        .where((event) => event.data != null && event.data!.isNotEmpty)
        .map((event) {
          final json = jsonDecode(event.data!) as Map<String, dynamic>;
          return IncomingTransferEvent.fromJson(json);
        });
  }

  Future<PolicyResponse> setPolicy({
    required String bearerToken,
    required SetPolicyRequest request,
  }) async {
    final response = await _apiClient.dio.put<dynamic>(
      '/transferkit/receive/policy',
      data: request.toJson(),
      options: _options(bearerToken),
    );
    return PolicyResponse.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<PolicyResponse> getPolicy({
    required String bearerToken,
  }) async {
    final response = await _apiClient.dio.get<dynamic>(
      '/transferkit/receive/policy',
      options: _options(bearerToken),
    );
    return PolicyResponse.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<AddHistoryResponse> addHistory({
    required String bearerToken,
    required AddHistoryRequest request,
  }) async {
    final response = await _apiClient.dio.post<dynamic>(
      '/transferkit/history',
      data: request.toJson(),
      options: _options(bearerToken),
    );
    return AddHistoryResponse.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<List<TransferHistoryRecord>> getHistory({
    required String bearerToken,
    String? deviceId,
    String? userId,
  }) async {
    final response = await _apiClient.dio.get<dynamic>(
      '/transferkit/history',
      queryParameters: <String, dynamic>{
        if (deviceId != null) 'deviceId': deviceId,
        if (userId != null) 'userId': userId,
      },
      options: _options(bearerToken),
    );
    final items = response.data as List<dynamic>? ?? const <dynamic>[];
    return items
        .whereType<Map>()
        .map(
          (item) =>
              TransferHistoryRecord.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  Future<StatusResponse> deleteHistory({
    required String bearerToken,
    required String recordId,
    String? deviceId,
    String? userId,
  }) async {
    final response = await _apiClient.dio.delete<dynamic>(
      '/transferkit/history/$recordId',
      queryParameters: <String, dynamic>{
        if (deviceId != null) 'deviceId': deviceId,
        if (userId != null) 'userId': userId,
      },
      options: _options(bearerToken),
    );
    return StatusResponse.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<StatusResponse> clearHistory({
    required String bearerToken,
    String? deviceId,
    String? userId,
  }) async {
    final response = await _apiClient.dio.delete<dynamic>(
      '/transferkit/history',
      queryParameters: <String, dynamic>{
        if (deviceId != null) 'deviceId': deviceId,
        if (userId != null) 'userId': userId,
      },
      options: _options(bearerToken),
    );
    return StatusResponse.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Options _options(String bearerToken) => Options(
    headers: <String, dynamic>{
      HttpHeaders.authorizationHeader: 'Bearer $bearerToken',
    },
  );
}
