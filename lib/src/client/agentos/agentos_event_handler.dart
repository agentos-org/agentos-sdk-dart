import 'dart:async';

import '../appkit/dto.dart';

abstract class AgentOSEventHandler {
  Future<void> onWelcome(Welcome welcome);

  Future<void> onAgents(Agents agents) async {}

  @Deprecated('AppKit no longer emits call events; kept for compatibility.')
  Future<void> onCall(Call call) async {}

  Future<void> onDone();

  Future<void> onError(Exception error);
}
