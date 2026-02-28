import 'dart:async';

import '../appkit/dto.dart';

abstract class AgentOSEventHandler {
  Future<void> onWelcome(Welcome welcome);

  Future<void> onCallApp(Call call) async {}

  Future<void> onDone();

  Future<void> onError(Exception error);
}
