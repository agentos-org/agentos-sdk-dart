import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// AgentOS 固定用户级 scope（见后端接入文档 §1）。
const List<String> kDefaultAgentOsScopes = [
  'openid',
  'profile',
  'email',
  'phone',
  'agentos.read',
  'agentos.write',
];

const _unreserved =
    'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';

/// 生成 PKCE `code_verifier`（43–128 字符）。
String generateCodeVerifier([int length = 64]) {
  final random = Random.secure();
  return List.generate(
    length.clamp(43, 128),
    (_) => _unreserved[random.nextInt(_unreserved.length)],
  ).join();
}

String generateOpaqueToken([int length = 32]) {
  return generateCodeVerifier(length);
}

/// `BASE64URL(SHA256(code_verifier))`，无 padding。
String codeChallengeS256(String codeVerifier) {
  final digest = sha256.convert(utf8.encode(codeVerifier));
  return base64Url.encode(digest.bytes).replaceAll('=', '');
}
