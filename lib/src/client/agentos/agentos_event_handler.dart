import 'dart:async';

import '../appkit/dto.dart';

abstract class AgentOSEventHandler {
  Future<void> onWelcome(Welcome welcome);

  Future<void> onCall(Call call);

  Future<void> onDone();

  Future<void> onError(Exception error);
}
