import 'dart:io';

import 'package:dio/dio.dart';

import '../../utils/api_client.dart';
import 'dto.dart';

/// 新 AuthKit 流程的本机投递客户端。
///
/// 只做一件事：把第三方 Server 返回的 `launchUri` 交给本机 AgentOS Desktop。
/// 不实现任何 OAuth 端点，也不会拿到 authorization code / ID Token / access
/// token —— 这些只在第三方 Server 与 AgentOS Server 之间流转。
///
/// 与将被下线的 `/authkit/*` 分开挂载，因此旧端点移除不影响本客户端。
class AuthKitClient {
  AuthKitClient({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  static const String basePath = '/authkit';

  /// 不等待用户决定时的响应超时。
  static const Duration _openTimeout = Duration(seconds: 15);

  final ApiClient _apiClient;

  /// 投递授权请求。
  ///
  /// 不抛网络异常：本机不可用、Desktop 未就绪等都会转成带 `errorCode` 的
  /// [AuthorizationPresentationResult]，便于调用方直接提示用户。
  /// 401/403 仍以 [DioException] 抛出，交由 SDK 的 app token 重试逻辑处理。
  Future<AuthorizationPresentationResult> open({
    required String bearerToken,
    required OpenAuthorizationRequest request,
  }) async {
    if (!isValidAuthorizationLaunchUri(request.launchUri)) {
      return const AuthorizationPresentationResult.failed(
        errorCode: AuthorizationErrorCodes.invalidLaunchUri,
        message: 'launchUri must be the value returned by your server',
      );
    }

    // 等待决定时给足时间，否则读超时会被误判为投递失败
    final receiveTimeout = request.waitForDecision
        ? (request.decisionTimeout ?? const Duration(minutes: 3)) +
            const Duration(seconds: 10)
        : _openTimeout;

    try {
      final response = await _apiClient.dio.post<dynamic>(
        '$basePath/open',
        data: request.toJson(),
        options: _options(bearerToken, receiveTimeout: receiveTimeout),
      );
      return AuthorizationPresentationResult.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      if (statusCode == 401 || statusCode == 403) rethrow;
      return _resultFromDioException(e);
    }
  }

  /// 探测本机是否已具备承载授权界面的能力。
  ///
  /// Desktop 未运行、或已运行但启动流程未完成时都会返回 false，可用于在发起
  /// 登录前提示用户安装 / 启动 / 解锁 AgentOS Desktop。
  Future<bool> isReady({required String bearerToken}) async {
    try {
      final response = await _apiClient.dio.get<dynamic>(
        '$basePath/status',
        options: _options(bearerToken, receiveTimeout: _openTimeout),
      );
      final data = Map<String, dynamic>.from(response.data as Map);
      return data['ready'] == true;
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      if (statusCode == 401 || statusCode == 403) rethrow;
      return false;
    }
  }

  AuthorizationPresentationResult _resultFromDioException(DioException e) {
    // 网关返回的结构化错误优先，它比本地推断更准确
    final data = e.response?.data;
    if (data is Map && data['status'] != null) {
      return AuthorizationPresentationResult.fromJson(
        Map<String, dynamic>.from(data),
      );
    }

    switch (e.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
        return const AuthorizationPresentationResult.failed(
          errorCode: AuthorizationErrorCodes.desktopNotRunning,
          message: 'AgentOS Desktop is not reachable on this machine',
        );
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return const AuthorizationPresentationResult.failed(
          errorCode: AuthorizationErrorCodes.timeout,
        );
      case DioExceptionType.unknown:
        if (e.error is SocketException) {
          return const AuthorizationPresentationResult.failed(
            errorCode: AuthorizationErrorCodes.desktopNotRunning,
            message: 'AgentOS Desktop is not reachable on this machine',
          );
        }
        return AuthorizationPresentationResult.failed(
          errorCode: AuthorizationErrorCodes.deliveryFailed,
          message: e.message,
        );
      default:
        return AuthorizationPresentationResult.failed(
          errorCode: AuthorizationErrorCodes.deliveryFailed,
          message: e.message,
        );
    }
  }

  Options _options(String bearerToken, {required Duration receiveTimeout}) =>
      Options(
        headers: <String, dynamic>{
          HttpHeaders.authorizationHeader: 'Bearer $bearerToken',
        },
        receiveTimeout: receiveTimeout,
      );
}
