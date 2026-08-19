import 'dart:io';

import 'package:agentos_sdk/agentos_sdk.dart';
import 'package:agentos_sdk/src/utils/api_client.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';

const String _validLaunchUri =
    'agentos://oauth2/authorize?request_id=ar_83d94c';

void main() {
  group('isValidAuthorizationLaunchUri', () {
    test('accepts the shape issued by AgentOS Server', () {
      expect(isValidAuthorizationLaunchUri(_validLaunchUri), isTrue);
    });

    test('rejects wrong scheme, host, path or missing request_id', () {
      const invalid = <String>[
        '',
        'https://oauth2/authorize?request_id=ar_1',
        'agentos://open?request_id=ar_1',
        'agentos://oauth2/token?request_id=ar_1',
        'agentos://oauth2/authorize',
        'agentos://oauth2/authorize?request_id=',
      ];
      for (final raw in invalid) {
        expect(
          isValidAuthorizationLaunchUri(raw),
          isFalse,
          reason: 'should reject "$raw"',
        );
      }
    });
  });

  group('AuthKitModule.openAuthorization', () {
    test('returns opened and never leaks OAuth credentials', () async {
      final interceptor = _AuthKitInterceptor();
      final sdk = await _buildSdk(interceptor);

      final result = await sdk.authkit.openAuthorization(
        launchUri: _validLaunchUri,
      );

      expect(result.status, AuthorizationPresentationStatus.opened);
      expect(result.errorCode, isNull);

      // 返回值只能描述本机交互状态
      expect(
        result.toJson().keys,
        everyElement(isIn(<String>['status', 'errorCode', 'message'])),
      );
    });

    test('passes launchUri through untouched', () async {
      final interceptor = _AuthKitInterceptor();
      final sdk = await _buildSdk(interceptor);

      await sdk.authkit.openAuthorization(launchUri: _validLaunchUri);

      expect(interceptor.lastOpenBody?['launchUri'], equals(_validLaunchUri));
      expect(interceptor.lastOpenPath, equals('/authkit/open'));
    });

    test('omits waitForDecision unless requested', () async {
      final interceptor = _AuthKitInterceptor();
      final sdk = await _buildSdk(interceptor);

      await sdk.authkit.openAuthorization(launchUri: _validLaunchUri);
      expect(interceptor.lastOpenBody?.containsKey('waitForDecision'), isFalse);

      await sdk.authkit.openAuthorization(
        launchUri: _validLaunchUri,
        waitForDecision: true,
        decisionTimeout: const Duration(seconds: 90),
      );
      expect(interceptor.lastOpenBody?['waitForDecision'], isTrue);
      expect(interceptor.lastOpenBody?['timeoutMs'], equals(90000));
    });

    test('rejects a malformed launchUri without a network call', () async {
      final interceptor = _AuthKitInterceptor();
      final sdk = await _buildSdk(interceptor);

      final result = await sdk.authkit.openAuthorization(
        launchUri: 'https://evil.example/authorize?request_id=ar_1',
      );

      expect(result.status, AuthorizationPresentationStatus.failed);
      expect(result.errorCode, AuthorizationErrorCodes.invalidLaunchUri);
      expect(interceptor.lastOpenPath, isNull);
    });

    test('surfaces submitted and denied decisions', () async {
      for (final entry in <String, AuthorizationPresentationStatus>{
        'submitted': AuthorizationPresentationStatus.submitted,
        'denied': AuthorizationPresentationStatus.denied,
      }.entries) {
        final interceptor = _AuthKitInterceptor(
          openResponse: <String, dynamic>{'status': entry.key},
        );
        final sdk = await _buildSdk(interceptor);

        final result = await sdk.authkit.openAuthorization(
          launchUri: _validLaunchUri,
          waitForDecision: true,
        );

        expect(result.status, entry.value);
      }
    });

    test('maps a structured gateway error to errorCode', () async {
      final interceptor = _AuthKitInterceptor(
        openStatusCode: 503,
        openResponse: <String, dynamic>{
          'status': 'failed',
          'errorCode': AuthorizationErrorCodes.desktopNotReady,
          'message': 'not ready',
        },
      );
      final sdk = await _buildSdk(interceptor);

      final result = await sdk.authkit.openAuthorization(
        launchUri: _validLaunchUri,
      );

      expect(result.status, AuthorizationPresentationStatus.failed);
      expect(result.errorCode, AuthorizationErrorCodes.desktopNotReady);
      expect(result.message, 'not ready');
    });

    test('reports desktop_not_running when the gateway is unreachable',
        () async {
      final interceptor = _AuthKitInterceptor(
        openFailure: DioExceptionType.connectionError,
      );
      final sdk = await _buildSdk(interceptor);

      final result = await sdk.authkit.openAuthorization(
        launchUri: _validLaunchUri,
      );

      expect(result.status, AuthorizationPresentationStatus.failed);
      expect(result.errorCode, AuthorizationErrorCodes.desktopNotRunning);
    });

    test('reports timeout when the decision wait exceeds the deadline',
        () async {
      final interceptor = _AuthKitInterceptor(
        openFailure: DioExceptionType.receiveTimeout,
      );
      final sdk = await _buildSdk(interceptor);

      final result = await sdk.authkit.openAuthorization(
        launchUri: _validLaunchUri,
      );

      expect(result.errorCode, AuthorizationErrorCodes.timeout);
    });

    test('treats a SocketException as an unreachable desktop', () async {
      final interceptor = _AuthKitInterceptor(
        openFailure: DioExceptionType.unknown,
        openFailureError: const SocketException('connection refused'),
      );
      final sdk = await _buildSdk(interceptor);

      final result = await sdk.authkit.openAuthorization(
        launchUri: _validLaunchUri,
      );

      expect(result.errorCode, AuthorizationErrorCodes.desktopNotRunning);
    });
  });

  group('AuthKitModule.isAuthorizationReady', () {
    test('reflects the gateway readiness flag', () async {
      final ready = await (await _buildSdk(
        _AuthKitInterceptor(statusReady: true),
      )).authkit.isAuthorizationReady();
      expect(ready, isTrue);

      final notReady = await (await _buildSdk(
        _AuthKitInterceptor(statusReady: false),
      )).authkit.isAuthorizationReady();
      expect(notReady, isFalse);
    });

    test('returns false when the gateway is unreachable', () async {
      final sdk = await _buildSdk(
        _AuthKitInterceptor(
          statusFailure: DioExceptionType.connectionError,
        ),
      );

      expect(await sdk.authkit.isAuthorizationReady(), isFalse);
    });
  });
}

Future<AgentOSSDK> _buildSdk(_AuthKitInterceptor interceptor) async {
  final dio = Dio(BaseOptions(baseUrl: 'http://fake.local'))
    ..interceptors.add(interceptor);
  final sdk = AgentOSSDK(apiClient: ApiClient(dio: dio));
  await sdk.agentos.registerBundle(bundleId: 'com.demo.appauth');
  return sdk;
}

class _AuthKitInterceptor extends Interceptor {
  _AuthKitInterceptor({
    this.openResponse,
    this.openStatusCode = 200,
    this.openFailure,
    this.openFailureError,
    this.statusReady = true,
    this.statusFailure,
  });

  final Map<String, dynamic>? openResponse;
  final int openStatusCode;
  final DioExceptionType? openFailure;
  final Object? openFailureError;
  final bool statusReady;
  final DioExceptionType? statusFailure;

  String? lastOpenPath;
  Map<String, dynamic>? lastOpenBody;
  String? lastAuthorizationHeader;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (options.path == '/appkit/register') {
      handler.resolve(
        Response<dynamic>(
          requestOptions: options,
          statusCode: 200,
          data: <String, dynamic>{
            'token': 'appauth-token',
            'bundleId': 'com.demo.appauth',
          },
        ),
      );
      return;
    }

    if (options.path == '/authkit/open') {
      lastOpenPath = options.path;
      lastOpenBody = Map<String, dynamic>.from(options.data as Map);
      lastAuthorizationHeader = options.headers['Authorization'] as String?;

      final failure = openFailure;
      if (failure != null) {
        handler.reject(
          DioException(
            requestOptions: options,
            type: failure,
            error: openFailureError,
          ),
        );
        return;
      }

      final body = openResponse ?? <String, dynamic>{'status': 'opened'};
      if (openStatusCode >= 200 && openStatusCode < 300) {
        handler.resolve(
          Response<dynamic>(
            requestOptions: options,
            statusCode: openStatusCode,
            data: body,
          ),
        );
      } else {
        handler.reject(
          DioException(
            requestOptions: options,
            type: DioExceptionType.badResponse,
            response: Response<dynamic>(
              requestOptions: options,
              statusCode: openStatusCode,
              data: body,
            ),
          ),
        );
      }
      return;
    }

    if (options.path == '/authkit/status') {
      final failure = statusFailure;
      if (failure != null) {
        handler.reject(
          DioException(requestOptions: options, type: failure),
        );
        return;
      }
      handler.resolve(
        Response<dynamic>(
          requestOptions: options,
          statusCode: 200,
          data: <String, dynamic>{'ready': statusReady},
        ),
      );
      return;
    }

    handler.reject(
      DioException(
        requestOptions: options,
        message: 'Unexpected request: ${options.method} ${options.path}',
      ),
    );
  }
}
