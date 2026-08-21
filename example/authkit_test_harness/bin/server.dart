import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';

import '../lib/agentos_server_client.dart';
import '../lib/harness_config.dart';
import '../lib/pkce.dart';
import '../lib/transaction_store.dart';

/// 模拟第三方 Server（如 Message Server），对接真实 AgentOS Server。
///
/// 配置见 [HarnessConfig]；启动：
///   dart run bin/server.dart
void main() async {
  final agentosBase = HarnessConfig.agentosServerBase;
  final oauthClientId = HarnessConfig.clientId;
  final port = HarnessConfig.port;
  final publicBase = HarnessConfig.publicBase;
  final store = LoginTransactionStore();
  final callbackUri = HarnessConfig.callbackUri;
  final router = Router();

  router.get('/', (_) {
    return Response.ok(
      jsonEncode({
        'name': 'AuthKit Third-Party Server (harness)',
        'agentOsServerBase': agentosBase,
        'oauthClientId': oauthClientId,
        'registeredRedirectUri': callbackUri,
        'endpoints': {
          'start': 'POST /auth/agentos/start',
          'callback': 'GET /auth/agentos/callback',
          'transaction': 'GET /auth/agentos/transactions/{transactionId}',
          'complete': 'POST /auth/agentos/transactions/{transactionId}/complete',
        },
      }),
      headers: {'content-type': 'application/json'},
    );
  });

  router.post('/auth/agentos/start', (Request request) async {
    final state = generateOpaqueToken();
    final nonce = generateOpaqueToken();
    final codeVerifier = generateCodeVerifier();
    final codeChallenge = codeChallengeS256(codeVerifier);
    final agentos = AgentOsServerClient(baseUrl: agentosBase);

    try {
      final created = await agentos.createAppAuthorizationRequest(
        clientId: oauthClientId,
        redirectUri: callbackUri,
        state: state,
        nonce: nonce,
        codeChallenge: codeChallenge,
      );

      final tx = store.createTransaction(
        requestId: created.requestId,
        launchUri: created.launchUri,
        state: state,
        codeVerifier: codeVerifier,
        nonce: nonce,
        clientId: oauthClientId,
        redirectUri: callbackUri,
        authorizationExpiresIn: Duration(seconds: created.expiresIn),
      );

      stdout.writeln(
        '[start] requestId=${created.requestId} transactionId=${tx.transactionId}',
      );

      return Response.ok(
        jsonEncode({
          'transactionId': tx.transactionId,
          'transactionSecret': tx.transactionSecret,
          'authorizationExpiresIn': created.expiresIn,
          'transactionExpiresIn': store.transactionTtl.inSeconds,
          'launchUri': created.launchUri,
          'requestId': created.requestId,
          'redirectUri': callbackUri,
          'hint':
              'Client 调 sdk.authkit.openAuthorization(launchUri: ...)；'
              'Desktop 需已登录 $agentosBase。',
        }),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      stdout.writeln('[start] AgentOS 创建授权请求失败: $e');
      return Response(
        502,
        body: jsonEncode({
          'error': 'agentos_server_error',
          'message': '$e',
        }),
        headers: {'content-type': 'application/json'},
      );
    } finally {
      agentos.close();
    }
  });

  router.get('/auth/agentos/callback', (Request request) async {
    final state = request.url.queryParameters['state'];
    final code = request.url.queryParameters['code'];
    final error = request.url.queryParameters['error'];

    if (state == null || state.isEmpty) {
      return Response(400, body: 'missing state');
    }

    final ok = store.authorizeCallback(state: state, code: code, error: error);
    if (!ok) {
      return Response(
        400,
        body: jsonEncode({
          'error': 'invalid_state_or_expired',
          'message': 'state 无效、事务已处理或已过期',
        }),
        headers: {'content-type': 'application/json'},
      );
    }

    final tx = store.findByState(state)!;

    if (tx.status == 'completed' && code != null && code.isNotEmpty) {
      final agentos = AgentOsServerClient(baseUrl: agentosBase);
      try {
        tx.agentOsTokenResponse = await agentos.exchangeAuthorizationCode(
          clientId: tx.clientId,
          code: code,
          redirectUri: tx.redirectUri,
          codeVerifier: tx.codeVerifier,
        );
        stdout.writeln(
          '[callback] token exchange OK transactionId=${tx.transactionId}',
        );
      } catch (e) {
        tx.status = 'error';
        tx.error = 'token_exchange_failed';
        stdout.writeln('[callback] token exchange failed: $e');
        return Response(
          502,
          body: jsonEncode({
            'error': 'token_exchange_failed',
            'message': '$e',
          }),
          headers: {'content-type': 'application/json'},
        );
      } finally {
        agentos.close();
      }
    }

    stdout.writeln(
      '[callback] transactionId=${tx.transactionId} status=${tx.status}'
      '${code != null ? ' code=<received>' : ''}'
      '${error != null ? ' error=$error' : ''}',
    );

    return Response.ok(
      jsonEncode({
        'status': 'callback_received',
        'transactionId': tx.transactionId,
        'transactionStatus': tx.status,
        if (tx.agentOsTokenResponse != null) 'tokenExchanged': true,
      }),
      headers: {'content-type': 'application/json'},
    );
  });

  router.get('/auth/agentos/transactions/<transactionId>', (
    Request request,
    String transactionId,
  ) {
    final secret = _bearerSecret(request);
    final tx = store.findByTransactionId(transactionId);
    if (tx == null) {
      return Response.notFound(jsonEncode({'error': 'not_found'}));
    }
    if (secret == null || secret != tx.transactionSecret) {
      return Response.forbidden(jsonEncode({'error': 'invalid_secret'}));
    }

    return Response.ok(
      jsonEncode({
        'transactionId': tx.transactionId,
        'status': tx.status,
        'expiresAt': tx.expiresAt.toIso8601String(),
        if (tx.error != null) 'error': tx.error,
      }),
      headers: {'content-type': 'application/json'},
    );
  });

  router.post('/auth/agentos/transactions/<transactionId>/complete', (
    Request request,
    String transactionId,
  ) async {
    final secret = _bearerSecret(request);
    final tx = store.findByTransactionId(transactionId);
    if (tx == null) {
      return Response.notFound(jsonEncode({'error': 'not_found'}));
    }
    if (secret == null || secret != tx.transactionSecret) {
      return Response.forbidden(jsonEncode({'error': 'invalid_secret'}));
    }
    if (tx.status != 'completed') {
      return Response(
        409,
        body: jsonEncode({
          'error': 'not_ready',
          'status': tx.status,
        }),
        headers: {'content-type': 'application/json'},
      );
    }

    final tokens = tx.agentOsTokenResponse;
    if (tokens == null) {
      return Response(
        502,
        body: jsonEncode({
          'error': 'token_not_exchanged',
          'message': 'callback 后未完成 /oauth2/token 兑换',
        }),
        headers: {'content-type': 'application/json'},
      );
    }

    final accessToken = tokens['access_token'] as String?;
    Map<String, dynamic>? userInfo;
    String? userInfoError;
    if (accessToken != null && accessToken.isNotEmpty) {
      final agentos = AgentOsServerClient(baseUrl: agentosBase);
      try {
        userInfo = await agentos.fetchUserInfo(accessToken: accessToken);
        stdout.writeln(
          '[complete] userInfo sub=${userInfo['sub']} name=${userInfo['name']}',
        );
      } catch (e) {
        userInfoError = '$e';
        stdout.writeln('[complete] fetch user info failed: $e');
      } finally {
        agentos.close();
      }
    }

    return Response.ok(
      jsonEncode({
        if (userInfo != null) 'user': userInfo,
        if (userInfoError != null) 'userInfoError': userInfoError,
        'accessToken': tokens['access_token'],
        'refreshToken': tokens['refresh_token'],
        'idToken': tokens['id_token'],
        'scope': tokens['scope'],
        'source': 'agentos_server',
      }),
      headers: {'content-type': 'application/json'},
    );
  });

  final handler = Pipeline()
      .addMiddleware(logRequests())
      .addHandler(router.call);

  final server =
      await shelf_io.serve(handler, InternetAddress.loopbackIPv4, port);

  stdout.writeln('Third-party harness server: $publicBase (port ${server.port})');
  stdout.writeln('AgentOS Server: $agentosBase (clientId=$oauthClientId)');
  stdout.writeln('Callback URI: $callbackUri');
  stdout.writeln('Desktop: 已登录同一 AgentOS 环境');
  stdout.writeln('Start: curl -s -X POST $publicBase/auth/agentos/start | jq');
}

String? _bearerSecret(Request request) {
  final auth = request.headers['authorization'] ?? '';
  if (!auth.startsWith('Bearer ')) return null;
  return auth.substring(7).trim();
}
