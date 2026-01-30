import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../schdules/data/models/task_model.dart';

class AiRepository {
  final ChatSession _chat;

  AiRepository({required String apiKey})
    : _chat = GenerativeModel(
        model: 'gemini-3-flash-preview',
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
        ),
      ).startChat(history: [Content.system(_systemPrompt)]);

  Future<AiResponse> sendMessage(
    String message,
    List<TaskModel> currentTasks,
  ) async {
    // We send the current tasks as context for every message to keep the AI updated
    // or we could rely on history if we update the history manually, but passing context is safer for accuracy.
    // To save tokens, we can summarize or only send relevant tasks if the list is huge.
    // For now, we'll send a simplified list of today's tasks.

    final tasksJson = currentTasks
        .map(
          (t) => {
            'id': t.id,
            'name': t.name,
            'date': t.taskDate.toIso8601String(),
            'start': t.startTime?.toIso8601String(),
            'end': t.endTime?.toIso8601String(),
            'completed': t.completed,
          },
        )
        .toList();

    final userContent = Content.text('''
User Message: $message

Current Date: ${DateTime.now().toIso8601String()}

Current Context (Tasks):
${jsonEncode(tasksJson)}
''');

    final response = await _chat.sendMessage(userContent);
    final text = response.text;

    if (text == null) {
      throw Exception('No response from AI');
    }

    try {
      final json = jsonDecode(text);
      return AiResponse.fromJson(json);
    } catch (e) {
      // Fallback if JSON parsing fails (e.g. if model ignored instructions)
      // Ideally we retry or have a robust error handling
      print('AI JSON Parse Error: $e\nResponse: $text');
      return AiResponse(
        message:
            "I'm having trouble processing that request properly. (Internal JSON Error)",
        actions: [],
      );
    }
  }

  static const _systemPrompt = '''
You are a helpful assistant directly integrated into a Task Management App.
Your goal is to help the user manage their schedule.

You can Read, Add, Update, and Delete tasks.
You will receive the user's message and a list of current tasks in the context.

You MUST respond in strict JSON format.
The JSON structure must be:
{
  "message": "A natural language response to the user explaining what you did or answering their question.",
  "actions": [
    {
      "type": "add" | "update" | "delete",
      "data": { ...task_fields... } // For add/update
      "id": "task_id" // For update/delete
    }
  ]
}

Task Fields for 'data':
- name (required string)
- desc (optional string)
- task_date (required string ISO8601 YYYY-MM-DD)
- start_time (optional string ISO8601)
- end_time (optional string ISO8601)
- category (optional string, default 'General')
- color_value (optional int, default 0xFF004D61)
- one_time (boolean, default true)

Rules:
1. Always analyze the "Current Context" before answering.
2. If the user asks to "add a task", generate an "add" action.
3. If the user asks to "change/reschedule", generate an "update" action.
4. If the user asks to "remove/delete", generate a "delete" action.
5. If the user just chats, return empty actions list.
6. Be concise in your "message".
7. For dates, use the current year/month unless specified. Assume "today" is the date found in the context or system time.
''';
}

class AiResponse {
  final String message;
  final List<AiAction> actions;

  AiResponse({required this.message, required this.actions});

  factory AiResponse.fromJson(Map<String, dynamic> json) {
    return AiResponse(
      message: json['message'] ?? '',
      actions:
          (json['actions'] as List?)
              ?.map((e) => AiAction.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class AiAction {
  final String type; // 'add', 'update', 'delete'
  final String? id;
  final Map<String, dynamic>? data;

  AiAction({required this.type, this.id, this.data});

  factory AiAction.fromJson(Map<String, dynamic> json) {
    return AiAction(type: json['type'], id: json['id'], data: json['data']);
  }
}
