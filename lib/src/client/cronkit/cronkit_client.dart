import 'dart:io';

import 'package:dio/dio.dart';

import '../../utils/api_client.dart';
import 'dto.dart';

class CronKitClient {
  CronKitClient({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<CronTask> getTask({
    required String bearerToken,
    required String cronId,
  }) async {
    final response = await _apiClient.dio.get<dynamic>(
      '/cronkit/task',
      queryParameters: <String, dynamic>{'cronId': cronId},
      options: _options(bearerToken),
    );
    return CronTask.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  Future<List<CronTaskListItem>> listTasks({
    required String bearerToken,
    bool? enabled,
    int? offset,
    int? limit,
  }) async {
    final response = await _apiClient.dio.get<dynamic>(
      '/cronkit/task/list',
      queryParameters: <String, dynamic>{
        if (enabled != null) 'enabled': enabled,
        if (offset != null) 'offset': offset,
        if (limit != null) 'limit': limit,
      },
      options: _options(bearerToken),
    );
    final items = response.data as List<dynamic>? ?? const <dynamic>[];
    return items
        .whereType<Map>()
        .map(
          (item) => CronTaskListItem.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  Future<CronTask> createTask({
    required String bearerToken,
    required CronTaskCreateRequest request,
  }) async {
    final response = await _apiClient.dio.post<dynamic>(
      '/cronkit/task/create',
      data: request.toJson(),
      options: _options(bearerToken),
    );
    return CronTask.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  Future<CronTask> updateTask({
    required String bearerToken,
    required CronTaskUpdateRequest request,
  }) async {
    final response = await _apiClient.dio.post<dynamic>(
      '/cronkit/task/update',
      data: request.toJson(),
      options: _options(bearerToken),
    );
    return CronTask.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  Future<CronTaskDeleteResult> deleteTask({
    required String bearerToken,
    required String cronId,
  }) async {
    final response = await _apiClient.dio.post<dynamic>(
      '/cronkit/task/delete',
      data: CronTaskActionRequest(cronId: cronId).toJson(),
      options: _options(bearerToken),
    );
    return CronTaskDeleteResult.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<CronTask> enableTask({
    required String bearerToken,
    required String cronId,
  }) =>
      _setTaskEnabled(bearerToken: bearerToken, cronId: cronId, enabled: true);

  Future<CronTask> disableTask({
    required String bearerToken,
    required String cronId,
  }) =>
      _setTaskEnabled(bearerToken: bearerToken, cronId: cronId, enabled: false);

  Future<CronRun> runTaskNow({
    required String bearerToken,
    required String cronId,
    DateTime? scheduledAt,
  }) async {
    final response = await _apiClient.dio.post<dynamic>(
      '/cronkit/task/runNow',
      data: CronTaskRunNowRequest(
        cronId: cronId,
        scheduledAt: scheduledAt,
      ).toJson(),
      options: _options(bearerToken),
    );
    return CronRun.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  Future<CronRun> getRun({
    required String bearerToken,
    required String runId,
  }) async {
    final response = await _apiClient.dio.get<dynamic>(
      '/cronkit/run',
      queryParameters: <String, dynamic>{'runId': runId},
      options: _options(bearerToken),
    );
    return CronRun.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  Future<List<CronRunListItem>> listRuns({
    required String bearerToken,
    String? cronId,
    DateTime? after,
    DateTime? before,
    int? offset,
    int? limit,
  }) async {
    final response = await _apiClient.dio.get<dynamic>(
      '/cronkit/run/list',
      queryParameters: <String, dynamic>{
        if (cronId != null) 'cronId': cronId,
        if (after != null) 'after': after.toIso8601String(),
        if (before != null) 'before': before.toIso8601String(),
        if (offset != null) 'offset': offset,
        if (limit != null) 'limit': limit,
      },
      options: _options(bearerToken),
    );
    final items = response.data as List<dynamic>? ?? const <dynamic>[];
    return items
        .whereType<Map>()
        .map(
          (item) => CronRunListItem.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  Future<List<CronRunMessage>> listRunMessages({
    required String bearerToken,
    required String runId,
    int? offset,
    int? limit,
  }) async {
    final response = await _apiClient.dio.get<dynamic>(
      '/cronkit/run/messages',
      queryParameters: <String, dynamic>{
        'runId': runId,
        if (offset != null) 'offset': offset,
        if (limit != null) 'limit': limit,
      },
      options: _options(bearerToken),
    );
    final items = response.data as List<dynamic>? ?? const <dynamic>[];
    return items
        .whereType<Map>()
        .map((item) => CronRunMessage.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<CronDeleteRunResult> deleteRun({
    required String bearerToken,
    required String runId,
  }) async {
    final response = await _apiClient.dio.post<dynamic>(
      '/cronkit/run/delete',
      data: CronRunQuery(runId: runId).toJson(),
      options: _options(bearerToken),
    );
    return CronDeleteRunResult.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<CronTask> _setTaskEnabled({
    required String bearerToken,
    required String cronId,
    required bool enabled,
  }) async {
    final response = await _apiClient.dio.post<dynamic>(
      '/cronkit/task/setEnabled',
      data: CronTaskSetEnabledRequest(
        cronId: cronId,
        enabled: enabled,
      ).toJson(),
      options: _options(bearerToken),
    );
    return CronTask.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  Options _options(String bearerToken) => Options(
    headers: <String, dynamic>{
      HttpHeaders.authorizationHeader: 'Bearer $bearerToken',
    },
  );
}
