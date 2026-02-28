import 'common_dto.dart';
import 'messages_dto.dart';

abstract class AgentMessageHandler {
  Tool? tool;

  AgentMessageHandler({this.tool});

  /// When Agent Call Native Function, will callback onFunctionCall
  Future<ToolReturn> onFunctionCall(
    String sessionId,
    FunctionCall functionCall,
  ) async {
    if (tool != null) {
      Map<String, dynamic> result = await tool!.call(
        functionCall.name,
        functionCall.arguments,
      );
      return ToolReturn(id: functionCall.id, result: result);
    }
    return ToolReturn(
      id: functionCall.id,
      result: FunctionNotSupportedException(
        functionName: functionCall.name,
      ).toJson(),
    );
  }

  /// When Agent Stream Call Native Function, will stream callback onStreamFunctionCall
  Future<void> onStreamFunctionCall(
    String sessionId,
    FunctionCall functionCall,
    void Function(EventToolReturn) onToolReturn,
  ) async {
    await _defaultStreamFunctionCall(sessionId, functionCall, onToolReturn);
  }

  Future<void> _defaultStreamFunctionCall(
    String sessionId,
    FunctionCall functionCall,
    void Function(EventToolReturn) onToolReturn,
  ) async {
    if (tool != null) {
      try {
        await tool!.streamCall(functionCall.name, functionCall.arguments, (
          String event,
          Map<String, dynamic> onEvent,
        ) {
          final toolReturn = ToolReturn(id: functionCall.id, result: onEvent);
          final eventToolReturn = EventToolReturn(
            event: event,
            toolReturn: toolReturn,
          );
          onToolReturn(eventToolReturn);
        });
        return;
      } catch (e) {
        final toolReturn = ToolReturn(
          id: functionCall.id,
          result: <String, dynamic>{'error': e.toString()},
        );
        final eventToolReturn = EventToolReturn(
          event: EventType.ERROR,
          toolReturn: toolReturn,
        );
        onToolReturn(eventToolReturn);
        return;
      }
    }
    final toolReturn = ToolReturn(
      id: functionCall.id,
      result: FunctionNotSupportedException(
        functionName: functionCall.name,
      ).toJson(),
    );
    final eventToolReturn = EventToolReturn(
      event: EventType.ERROR,
      toolReturn: toolReturn,
    );
    onToolReturn(eventToolReturn);
  }

  /// When SSE connection receive a message, will callback onMessage()
  Future<void> onMessage(String sessionId, AgentMessage agentMessage);

  /// When SSE connection receive a chunk, will callback onChunk()
  Future<void> onChunk(String sessionId, AgentMessageChunk agentMessageChunk);

  /// When SSE connection DONE, will callback onDone()
  Future<void> onDone();

  /// When SSE Error, will callback onError(e)
  Future<void> onError(Exception e);
}
