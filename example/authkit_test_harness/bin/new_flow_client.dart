import 'dart:convert';
import 'dart:io';

import 'package:agentos_sdk/agentos_sdk.dart';

import '../lib/harness_config.dart';

/// 模拟第三方 Client：自家 Server 创建事务 → SDK 投递 launchUri → 轮询 → 领取 token。
///
/// 配置见 [HarnessConfig]；需先启动 bin/server.dart：
///   dart run bin/new_flow_client.dart
void main() async {
  final serverBase = HarnessConfig.publicBase;
  final gatewayBase = HarnessConfig.gatewayBase;
  final bundleId = HarnessConfig.bundleId;
  final waitForDecision = HarnessConfig.waitForDecision;
  final pollInterval = HarnessConfig.pollInterval;
  final pollTimeout = HarnessConfig.pollTimeout;

  final http = HttpClient();

  stdout.writeln('== AuthKit New Flow ==');
  stdout.writeln('Third-party Server: $serverBase');
  stdout.writeln('Bundle ID: $bundleId');
  stdout.writeln('');

  stdout.writeln('[1/5] POST /auth/agentos/start');
  final startResp = await _postJson(http, '$serverBase/auth/agentos/start', {});
  final transactionId = startResp['transactionId'] as String;
  final transactionSecret = startResp['transactionSecret'] as String;
  final launchUri = startResp['launchUri'] as String;

  stdout.writeln('      transactionId=$transactionId');
  stdout.writeln('      launchUri=$launchUri');
  if (startResp['hint'] != null) {
    stdout.writeln('      hint=${startResp['hint']}');
  }
  stdout.writeln('');

  stdout.writeln('[2/5] Deliver launchUri to Desktop via SDK');
  final sdk = AgentOSSDK(baseUrl: gatewayBase);
  try {
    await sdk.agentos.registerBundle(bundleId: bundleId);
  } catch (e) {
    stdout.writeln('      registerBundle 失败：$e');
    stdout.writeln('      → 确认 AgentOS Desktop 已启动并已登录');
    exit(4);
  }

  final result = await sdk.authkit.openAuthorization(
    launchUri: launchUri,
    waitForDecision: waitForDecision,
  );
  stdout.writeln('      status=${result.status.name}');
  if (result.errorCode != null) {
    stdout.writeln('      errorCode=${result.errorCode}');
    stdout.writeln('      message=${result.message ?? '-'}');
  }

  final payload = jsonEncode(result.toJson());
  for (final forbidden in const ['code', 'id_token', 'access_token']) {
    if (payload.contains('"$forbidden"')) {
      stderr.writeln('SDK 返回值包含凭证字段 "$forbidden"，违反流程约束');
      exit(5);
    }
  }

  if (result.isFailure) {
    stdout.writeln('');
    stdout.writeln('[done] 本机授权未能展示，终止');
    await sdk.dispose();
    http.close(force: true);
    exit(6);
  }

  await sdk.dispose();
  stdout.writeln('      请在 Desktop 弹窗中选择允许/拒绝');
  stdout.writeln('');

  stdout.writeln('[3/5] Poll transaction status');
  var txStatus = 'pending';
  final deadline = DateTime.now().add(pollTimeout);
  while (txStatus == 'pending' && DateTime.now().isBefore(deadline)) {
    await Future<void>.delayed(pollInterval);
    final poll = await _getJson(
      http,
      '$serverBase/auth/agentos/transactions/$transactionId',
      bearer: transactionSecret,
    );
    txStatus = poll['status'] as String;
    stdout.writeln('      status=$txStatus');
  }

  if (txStatus == 'denied') {
    stdout.writeln('[done] 用户拒绝');
    http.close(force: true);
    exit(2);
  }
  if (txStatus == 'error') {
    stdout.writeln('[done] 事务失败（可能是 token 兑换失败）');
    http.close(force: true);
    exit(3);
  }
  if (txStatus != 'completed') {
    stdout.writeln('[done] 事务未 completed: $txStatus');
    http.close(force: true);
    exit(3);
  }

  stdout.writeln('[4/5] POST /auth/agentos/transactions/.../complete');
  final complete = await _postJson(
    http,
    '$serverBase/auth/agentos/transactions/$transactionId/complete',
    {},
    bearer: transactionSecret,
  );
  stdout.writeln('      accessToken=${_shortToken(complete['accessToken'])}');
  stdout.writeln('      source=${complete['source']}');
  if (complete['idToken'] != null) {
    stdout.writeln('      idToken=<received>');
  }
  final user = complete['user'];
  if (user is Map) {
    stdout.writeln('      user=${jsonEncode(user)}');
  } else if (complete['userInfoError'] != null) {
    stdout.writeln('      userInfoError=${complete['userInfoError']}');
  }

  stdout.writeln('[5/5] Check AgentOS gateway');
  try {
    final probe = AgentOSSDK(baseUrl: gatewayBase);
    final version = await probe.agentos.getVersion();
    stdout.writeln('      gateway version=${version.version}');
    await probe.dispose();
  } catch (_) {
    stdout.writeln('      gateway unavailable');
  }

  stdout.writeln('');
  stdout.writeln('New flow OK.');
  http.close(force: true);
}

String _shortToken(Object? token) {
  final text = '$token';
  if (text.length <= 24) return text;
  return '${text.substring(0, 12)}...${text.substring(text.length - 8)}';
}

Future<Map<String, dynamic>> _getJson(
  HttpClient client,
  String url, {
  String? bearer,
}) async {
  final request = await client.getUrl(Uri.parse(url));
  if (bearer != null) {
    request.headers.set('authorization', 'Bearer $bearer');
  }
  final response = await request.close();
  final body = await response.transform(utf8.decoder).join();
  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw HttpException('GET $url -> ${response.statusCode}: $body');
  }
  return Map<String, dynamic>.from(jsonDecode(body) as Map);
}

Future<Map<String, dynamic>> _postJson(
  HttpClient client,
  String url,
  Map<String, dynamic> body, {
  String? bearer,
}) async {
  final request = await client.postUrl(Uri.parse(url));
  request.headers.set('content-type', 'application/json');
  if (bearer != null) {
    request.headers.set('authorization', 'Bearer $bearer');
  }
  request.write(jsonEncode(body));
  final response = await request.close();
  final text = await response.transform(utf8.decoder).join();
  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw HttpException('POST $url -> ${response.statusCode}: $text');
  }
  if (text.isEmpty) return {};
  return Map<String, dynamic>.from(jsonDecode(text) as Map);
}
