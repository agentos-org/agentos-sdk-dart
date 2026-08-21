/// AuthKit harness 联调配置。修改本文件即可，启动命令无需带参数。
abstract final class HarnessConfig {
  /// AgentOS Server API 根地址（含 `/agentos-server`），须与 Desktop 登录环境一致。
  static const String agentosServerBase =
      'http://192.168.2.39:3600/agentos-server';

  /// 已在 AgentOS 注册的 OAuth client_id。
  static const String clientId = '2089549592650526720';

  /// 第三方应用 bundleId，须与 AgentOS 注册信息一致。
  static const String bundleId = 'com.demo.authkit.harness';

  /// 第三方 Server 监听端口。
  static const int port = 9999;

  /// 对外 callback 基址；须与注册到 AgentOS 的 redirect_uri 前缀一致。
  static const String publicBase = 'http://127.0.0.1:9999';

  /// AgentOS Desktop 本机网关。
  static const String gatewayBase = 'http://localhost:8888';

  /// SDK 是否等待用户在 Desktop 弹窗中选择后再返回。
  static const bool waitForDecision = true;

  static const Duration pollInterval = Duration(seconds: 1);
  static const Duration pollTimeout = Duration(minutes: 3);

  static String get callbackUri => '$publicBase/auth/agentos/callback';
}
