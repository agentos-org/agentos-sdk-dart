import 'package:opentool_dart/opentool_client.dart' as opentool;

typedef FunctionCall = opentool.FunctionCall;


typedef ToolReturn = opentool.ToolReturn;


typedef Tool = opentool.Tool;


typedef EventType = opentool.EventType;


typedef FunctionNotSupportedException = opentool.FunctionNotSupportedException;


class AgentRoleType {
  static const String system = "developer"; // system prompt
  static const String user = "user"; // user
  static const String agent = "agent"; // agent
  static const String llm = "assistant"; // llm
  static const String tool = "tool"; // external tools
  static const String client = "client"; // external caller
}


class AgentMessageType {
  static const String text = "text"; //String
  static const String imageUrl = "imageUrl"; //String
  static const String dispatch = "dispatch"; //List<Dispatch>
  static const String toolCalls = "toolCalls"; //List<FunctionCall>
  static const String toolReturn = "toolReturn"; //ToolReturn
  static const String contentList = "contentList"; //List<Content>
  static const String reflection = "reflection"; //Reflection
  static const String taskStatus = "taskStatus"; //TaskStatus
  static const String functionCall = "functionCall"; //FunctionCall
  static const String reasoningContent = "reasoningContent"; //String
  static const String planning = "planning"; //PlanningContent
}


class TaskStatusType {
  static const String start = "start";
  static const String stop = "stop";
  static const String done = "done";
  static const String exception = "exception";
  static const String toolsStart = "toolsStart";
  static const String toolsDone = "toolsDone";
  static const String subAgentStart = "subAgentStart";
  static const String subAgentDone = "subAgentDone";
}


class AgentEventType {
  static const String message = "message";
  static const String chunk = "chunk";
  static const String functionCall = "functionCall";
}

