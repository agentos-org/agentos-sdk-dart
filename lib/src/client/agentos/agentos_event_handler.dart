import 'dart:async';

import '../appkit/dto.dart';

abstract class AgentOSEventHandler {
  Future<void> onWelcome(Welcome welcome);

  /// Handles generic AppKit business events such as OpenTool provisioning
  /// results. Existing handlers may ignore these events.
  Future<void> onAppEvent(AppEvent event) async {}

  Future<void> onDone();

  Future<void> onError(Exception error);
}
