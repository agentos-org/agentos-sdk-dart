import 'dart:convert';
import 'dart:io';

import 'pkce.dart';

/// 调用真实 AgentOS Server 的 S2（创建授权请求）与 `/oauth2/token`（换 token）。
class AgentOsServerClient {
  AgentOsServerClient({
    required String baseUrl,
    HttpClient? httpClient,
  })  : baseUrl = baseUrl.replaceAll(RegExp(r'/+$'), ''),
        _http = httpClient ?? HttpClient();

  final String baseUrl;
  final HttpClient _http;

  Future<CreateAuthorizationRequestResult> createAppAuthorizationRequest({
    required String clientId,
    required String redirectUri,
    required String state,
    required String nonce,
    required String codeChallenge,
    List<String> scopes = kDefaultAgentOsScopes,
  }) async {
    final uri = Uri.parse(
      '$baseUrl/api/v1/third/oauth2/app-authorization-requests',
    );
    final body = await _postJson(uri, {
      'clientId': clientId,
      'redirectUri': redirectUri,
      'scopes': scopes,
      'state': state,
      'nonce': nonce,
      'codeChallenge': codeChallenge,
      'codeChallengeMethod': 'S256',
    });

    final data = _unwrapData(body);
    final requestId = data['requestId'] as String?;
    final launchUri = data['launchUri'] as String?;
    if (requestId == null ||
        requestId.isEmpty ||
        launchUri == null ||
        launchUri.isEmpty) {
      throw StateError('AgentOS Server 未返回 requestId/launchUri: $body');
    }

    final expiresIn = data['expiresIn'];
    return CreateAuthorizationRequestResult(
      requestId: requestId,
      launchUri: launchUri,
      expiresIn: expiresIn is int ? expiresIn : int.tryParse('$expiresIn') ?? 180,
    );
  }

  Future<Map<String, dynamic>> fetchUserInfo({
    required String accessToken,
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/auth/user/info');
    final request = await _http.getUrl(uri);
    request.headers.set('accept', 'application/json');
    request.headers.set('authorization', 'Bearer $accessToken');

    final response = await request.close();
    final text = await response.transform(utf8.decoder).join();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException('GET $uri -> ${response.statusCode}: $text');
    }

    final body = Map<String, dynamic>.from(jsonDecode(text) as Map);
    return _unwrapData(body);
  }

  Future<Map<String, dynamic>> exchangeAuthorizationCode({
    required String clientId,
    required String code,
    required String redirectUri,
    required String codeVerifier,
  }) async {
    final uri = Uri.parse('$baseUrl/oauth2/token');
    final request = await _http.postUrl(uri);
    request.headers.set('content-type', 'application/x-www-form-urlencoded');
    request.write(Uri(
      queryParameters: {
        'grant_type': 'authorization_code',
        'client_id': clientId,
        'code': code,
        'redirect_uri': redirectUri,
        'code_verifier': codeVerifier,
      },
    ).query);

    final response = await request.close();
    final text = await response.transform(utf8.decoder).join();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException(
        'POST $uri -> ${response.statusCode}: $text',
      );
    }

    return Map<String, dynamic>.from(jsonDecode(text) as Map);
  }

  Future<Map<String, dynamic>> _postJson(
    Uri uri,
    Map<String, dynamic> payload,
  ) async {
    final request = await _http.postUrl(uri);
    request.headers.set('content-type', 'application/json');
    request.headers.set('accept', 'application/json');
    request.write(jsonEncode(payload));
    final response = await request.close();
    final text = await response.transform(utf8.decoder).join();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException('POST $uri -> ${response.statusCode}: $text');
    }
    return Map<String, dynamic>.from(jsonDecode(text) as Map);
  }

  Map<String, dynamic> _unwrapData(Map<String, dynamic> body) {
    if (!body.containsKey('data')) {
      return body;
    }
    final code = body['code'];
    if (code is int && code != 0 && code != 200) {
      final msg = body['msg'] ?? body['message'] ?? 'AgentOS error $code';
      throw HttpException('AgentOS business error $code: $msg');
    }
    final data = body['data'];
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return const {};
  }

  void close() => _http.close(force: true);
}

class CreateAuthorizationRequestResult {
  const CreateAuthorizationRequestResult({
    required this.requestId,
    required this.launchUri,
    required this.expiresIn,
  });

  final String requestId;
  final String launchUri;
  final int expiresIn;
}
