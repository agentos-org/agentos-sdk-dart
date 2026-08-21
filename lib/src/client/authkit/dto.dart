/// 本机授权交互的结果状态。
///
/// 刻意不含任何 OAuth 凭证：`submitted` 只表示 AgentOS Desktop 已把用户决定
/// 提交给 AgentOS Server，**不代表**第三方登录已完成。第三方 Client 必须以
/// 自己 Server 的登录事务状态为准。
enum AuthorizationPresentationStatus {
  /// Desktop 已展示授权页，用户尚未做出选择。
  opened,

  /// 用户已同意，Desktop 已把决定提交给 Server。
  submitted,

  /// 用户已拒绝。
  denied,

  /// 未能完成本机交互，详见 [AuthorizationPresentationResult.errorCode]。
  failed,
}

/// 授权错误码。与 `agentos-api` 的 `AuthKitErrorCodes` 保持一致。
class AuthorizationErrorCodes {
  AuthorizationErrorCodes._();

  /// 本机 AgentOS Desktop 未运行或网关不可达。
  static const String desktopNotRunning = 'desktop_not_running';

  /// Desktop 在运行，但授权界面尚未就绪（通常是启动未完成）。
  static const String desktopNotReady = 'desktop_not_ready';

  /// Desktop 未登录 AgentOS 账号。
  static const String desktopNotLoggedIn = 'desktop_not_logged_in';

  /// `launchUri` 不合法。应原样使用第三方 Server 返回的值，不要自行拼接。
  static const String invalidLaunchUri = 'invalid_launch_uri';

  /// 授权请求已过期，需重新发起登录。
  static const String authorizationExpired = 'authorization_expired';

  /// 授权请求不存在或已被处理。
  static const String authorizationNotFound = 'authorization_not_found';

  /// Desktop 无法访问 AgentOS Server。
  static const String serverUnavailable = 'server_unavailable';

  /// 投递通道失败。
  static const String deliveryFailed = 'delivery_failed';

  /// 等待本机交互超时。
  static const String timeout = 'timeout';
}

/// [AuthKitModule.openAuthorization] 的返回值。
class AuthorizationPresentationResult {
  const AuthorizationPresentationResult({
    required this.status,
    this.errorCode,
    this.message,
  });

  const AuthorizationPresentationResult.failed({
    required this.errorCode,
    this.message,
  }) : status = AuthorizationPresentationStatus.failed;

  factory AuthorizationPresentationResult.fromJson(Map<String, dynamic> json) {
    return AuthorizationPresentationResult(
      status: _statusFromName(json['status']),
      errorCode: json['errorCode'] as String?,
      message: json['message'] as String?,
    );
  }

  final AuthorizationPresentationStatus status;

  /// 失败原因，取值见 [AuthorizationErrorCodes]。
  final String? errorCode;

  /// 便于排查的补充说明，不含凭证信息。
  final String? message;

  bool get isFailure => status == AuthorizationPresentationStatus.failed;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'status': status.name,
        if (errorCode != null) 'errorCode': errorCode,
        if (message != null) 'message': message,
      };

  @override
  String toString() =>
      'AuthorizationPresentationResult(${status.name}'
      '${errorCode != null ? ', $errorCode' : ''})';

  static AuthorizationPresentationStatus _statusFromName(Object? raw) {
    final name = '${raw ?? ''}';
    for (final status in AuthorizationPresentationStatus.values) {
      if (status.name == name) return status;
    }
    return AuthorizationPresentationStatus.failed;
  }
}

/// 投递请求体。
class OpenAuthorizationRequest {
  const OpenAuthorizationRequest({
    required this.launchUri,
    this.waitForDecision = false,
    this.decisionTimeout,
  });

  /// 第三方 Server 从 AgentOS Server 取得的唤起地址，**原样透传**。
  final String launchUri;

  /// 是否等待用户做出选择。
  ///
  /// 默认 false：Desktop 展示授权页后立即返回 `opened`。第三方 Client 应通过
  /// 自己 Server 的事务状态感知最终结果，而不是依赖本机返回值。
  final bool waitForDecision;

  /// [waitForDecision] 为 true 时的等待上限；超时返回 `opened`。
  final Duration? decisionTimeout;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'launchUri': launchUri,
        if (waitForDecision) 'waitForDecision': true,
        if (decisionTimeout != null)
          'timeoutMs': decisionTimeout!.inMilliseconds,
      };
}

/// `launchUri` 的本地形状校验。
///
/// 只判断 scheme / host / path 与 `request_id` 是否存在，不解释 `request_id`
/// 的含义 —— 它对客户端是不透明值。校验失败可在发起网络请求前直接返回
/// [AuthorizationErrorCodes.invalidLaunchUri]。
bool isValidAuthorizationLaunchUri(String raw) {
  final uri = Uri.tryParse(raw.trim());
  if (uri == null) return false;
  if (uri.scheme.toLowerCase() != 'agentos') return false;
  if (uri.host.toLowerCase() != 'oauth2') return false;
  final path = uri.path.isEmpty ? '/authorize' : uri.path;
  if (path.toLowerCase() != '/authorize') return false;
  final requestId = uri.queryParameters['request_id']?.trim();
  return requestId != null && requestId.isNotEmpty;
}
