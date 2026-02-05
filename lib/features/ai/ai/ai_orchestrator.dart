import '../../schdules/domain/repo/schedule_repository.dart';
import 'ai_action_models.dart';
import 'ai_prompt_builder.dart';
import 'ai_response_parser.dart';
import 'ai_repository.dart';
import '../../../core/services/embedding_service.dart';
import '../../../core/utils/observability.dart';

class AiOrchestrator {
  final AiRepository _repository;

  AiOrchestrator({
    required String apiKey,
    required ScheduleRepository scheduleRepository,
    required EmbeddingService embeddingService,
  }) : _repository = AiRepository(
         apiKey: apiKey,
         scheduleRepository: scheduleRepository,
       );

  Future<(String, List<AiAction>, String?)> processUserMessage(
    String message, {
    String? traceId,
  }) async {
    // 1. Clear Instructions
    final systemPrompt = AiPromptBuilder.buildSystemPrompt();

    // 2. Process via Repository (Tool Loop)
    final responsePayload = await _repository.processUserMessage(
      userMessage: message,
      systemPrompt: systemPrompt,
      traceId: traceId,
    );

    // 3. Extract Text Response
    final parts = responsePayload['parts'] as List;
    final textPart = parts.firstWhere(
      (p) => p.containsKey('text'),
      orElse: () => {'text': ''},
    );
    final responseText = textPart['text'] as String;

    AvenueLogger.log(
      event: 'AI_FINAL_RESPONSE',
      layer: LoggerLayer.AI,
      traceId: traceId,
      payload: responseText,
    );

    // 4. Parse Response for UI metadata (Title, etc)
    final (msg, actions, suggestedTitle) = AiResponseParser.parse(responseText);

    return (msg, actions, suggestedTitle);
  }

  void clearHistory() {
    _repository.clearHistory();
  }

  void loadHistory(List<Map<String, dynamic>> messages) {
    _repository.loadHistory(messages);
  }
}
