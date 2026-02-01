import '../../schdules/domain/repo/schedule_repository.dart';
import 'ai_action_models.dart';
import 'ai_context_builder.dart';
import 'ai_executor.dart';
import 'ai_prompt_builder.dart';
import 'ai_response_parser.dart';
import 'gemini_http_client.dart';

class AiOrchestrator {
  final GeminiHttpClient _client;
  final AiContextBuilder _contextBuilder;
  final AiExecutor _executor;
  final List<Map<String, dynamic>> _history = [];

  AiOrchestrator({
    required String apiKey,
    required ScheduleRepository scheduleRepository,
  }) : _contextBuilder = AiContextBuilder(scheduleRepository),
       _executor = AiExecutor(scheduleRepository),
       _client = GeminiHttpClient(apiKey: apiKey, model: 'gemini-flash-latest');

  Future<(String, List<AiAction>)> processUserMessage(String message) async {
    // 1. Build Context
    final context = await _contextBuilder.buildContext();
    final systemPrompt = AiPromptBuilder.buildSystemPrompt(context);

    // 2. Prepare and send request
    final responseText = await _client.generateContent(
      systemPrompt: systemPrompt,
      history: _history,
      userMessage: message,
    );

    // 3. Parse Response
    final (msg, actions) = AiResponseParser.parse(responseText);

    // 4. Update History
    _history.add({
      'role': 'user',
      'parts': [
        {'text': message},
      ],
    });
    _history.add({
      'role': 'model',
      'parts': [
        {'text': responseText},
      ],
    });

    return (msg, actions);
  }

  Future<void> confirmAndExecute(AiAction action) async {
    await _executor.execute(action);
  }
}
