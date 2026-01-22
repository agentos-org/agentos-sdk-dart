import 'dart:io' show Platform;

import 'package:dio/dio.dart';

/// 基础 HTTP 客户端，默认指向本地服务。
class ApiClient {
  ApiClient({Dio? dio, String? baseUrl, BaseOptions? baseOptions})
    : _dio =
          dio ??
          Dio(
            baseOptions ??
                BaseOptions(
                  baseUrl:
                      baseUrl ??
                      Platform.environment['AGENTOS_BASEURL'] ??
                      'http://localhost:20261',
                  connectTimeout: const Duration(seconds: 5),
                  receiveTimeout: const Duration(seconds: 10),
                ),
          );

  final Dio _dio;

  Dio get dio => _dio;
}
