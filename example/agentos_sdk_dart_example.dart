import 'dart:io';

import 'package:agentos_sdk/agentos_sdk.dart';
import 'package:unique_id_dart/unique_id_dart.dart';

Future<void> main() async {
  final baseUrl =
      Platform.environment['AGENTOS_BASEURL'] ?? 'http://localhost:20261';
  final bundleId =
      Platform.environment['AGENTOS_BUNDLE_ID'] ?? 'com.demo.app.${uniqueId()}';
  final sdk = AgentOSSDK(baseUrl: baseUrl);

  print('Using AgentOS API at $baseUrl');

  try {
    final version = await sdk.agentos.getVersion();
    print('AgentOS API version: ${version.version}');
  } catch (e) {
    print('Failed to fetch version: $e');
  }

  try {
    await sdk.agentos.registerBundle(bundleId: bundleId);
    print('Registered bundle (bundleId: $bundleId)');
  } catch (e) {
    print('Failed to register bundle: $e');
  }

  try {
    await sdk.agentos.subscribe(_DemoEventHandler());
    await Future<void>.delayed(const Duration(milliseconds: 200));
  } catch (e) {
    print('Failed to subscribe to AppKit events: $e');
  }

  try {
    final tools = await sdk.agentkit.openToolList();
    print('OpenTool count: ${tools.length}');
  } catch (e) {
    print('Failed to list OpenTools: $e');
  }
}

class _DemoEventHandler extends AgentOSEventHandler {
  @override
  Future<void> onWelcome(Welcome welcome) async {
    print('Welcome bundleId: ${welcome.bundleId}');
  }

  @override
  Future<void> onCall(Call call) async {
    print('Call event: ${call.id}');
  }

  @override
  Future<void> onDone() async {
    print('SSE subscription ended');
  }

  @override
  Future<void> onError(Exception error) async {
    print('Failed to subscribe: $error');
  }
}
