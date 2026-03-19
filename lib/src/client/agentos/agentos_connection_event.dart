class AgentOSSubscribeOptions {
  const AgentOSSubscribeOptions({
    this.autoReconnect = true,
    this.maxReconnectAttempts = 3,
    this.reconnectDelay = const Duration(seconds: 1),
  }) : assert(maxReconnectAttempts > 0);

  final bool autoReconnect;
  final int maxReconnectAttempts;
  final Duration reconnectDelay;
}

enum AgentOSSubscribeConnectionStatus {
  connected,
  reconnecting,
  disconnected,
  reconnected,
}

class AgentOSSubscribeConnectionEvent {
  const AgentOSSubscribeConnectionEvent({
    required this.status,
    this.attempt = 0,
    this.error,
  });

  final AgentOSSubscribeConnectionStatus status;
  final int attempt;
  final Exception? error;

  bool get isConnected =>
      status == AgentOSSubscribeConnectionStatus.connected ||
      status == AgentOSSubscribeConnectionStatus.reconnected;
}
