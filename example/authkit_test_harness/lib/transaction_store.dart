import 'dart:math';

/// 第三方 Server 侧内存登录事务（保存 state / PKCE / token 兑换结果）。
class LoginTransaction {
  LoginTransaction({
    required this.transactionId,
    required this.transactionSecret,
    required this.state,
    required this.requestId,
    required this.expiresAt,
    required this.authorizationExpiresAt,
    required this.clientId,
    required this.redirectUri,
    required this.codeVerifier,
    required this.nonce,
    required this.launchUri,
  });

  final String transactionId;
  final String transactionSecret;
  final String state;
  final String requestId;
  final String clientId;
  final String redirectUri;
  final String codeVerifier;
  final String nonce;
  final String launchUri;

  /// 整个登录事务的有效期（指南示例 8 分钟）。
  final DateTime expiresAt;

  /// 授权请求本身的有效期（指南示例 3 分钟）。
  final DateTime authorizationExpiresAt;

  bool get isAuthorizationExpired =>
      DateTime.now().isAfter(authorizationExpiresAt);

  String status = 'pending';
  String? authorizationCode;
  String? error;
  DateTime? callbackReceivedAt;

  /// AgentOS `/oauth2/token` 响应。
  Map<String, dynamic>? agentOsTokenResponse;
}

class LoginTransactionStore {
  LoginTransactionStore({
    this.transactionTtl = const Duration(minutes: 8),
  });

  final Duration transactionTtl;

  final Map<String, LoginTransaction> _byTransactionId = {};
  final Map<String, String> _transactionIdByState = {};

  static final _random = Random.secure();

  static String _token(int bytes) {
    return List.generate(bytes, (_) => _random.nextInt(256))
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
  }

  LoginTransaction createTransaction({
    required String requestId,
    required String launchUri,
    required String state,
    required String codeVerifier,
    required String nonce,
    required String clientId,
    required String redirectUri,
    required Duration authorizationExpiresIn,
  }) {
    final transactionId = 'mtx_${_token(8)}';
    final transactionSecret = 'mts_${_token(16)}';
    final now = DateTime.now();

    final tx = LoginTransaction(
      transactionId: transactionId,
      transactionSecret: transactionSecret,
      state: state,
      requestId: requestId,
      clientId: clientId,
      redirectUri: redirectUri,
      codeVerifier: codeVerifier,
      nonce: nonce,
      launchUri: launchUri,
      expiresAt: now.add(transactionTtl),
      authorizationExpiresAt: now.add(authorizationExpiresIn),
    );

    _byTransactionId[transactionId] = tx;
    _transactionIdByState[state] = transactionId;
    return tx;
  }

  LoginTransaction? findByState(String state) {
    final id = _transactionIdByState[state];
    if (id == null) return null;
    return _byTransactionId[id];
  }

  LoginTransaction? findByTransactionId(String transactionId) {
    return _byTransactionId[transactionId];
  }

  bool authorizeCallback({
    required String state,
    String? code,
    String? error,
  }) {
    final tx = findByState(state);
    if (tx == null) return false;
    if (tx.status != 'pending') return false;
    if (DateTime.now().isAfter(tx.expiresAt)) {
      tx.status = 'expired';
      return false;
    }

    tx.callbackReceivedAt = DateTime.now();
    if (error != null && error.isNotEmpty) {
      tx.status = 'denied';
      tx.error = error;
      return true;
    }

    tx.authorizationCode = code;
    tx.status = 'completed';
    return true;
  }
}
