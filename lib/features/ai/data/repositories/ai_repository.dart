import 'package:avenue/features/ai/ai/ai_tools.dart';
import 'package:avenue/features/ai/ai/ai_tool_executor.dart';
import 'package:avenue/features/ai/ai/open_router_http_client.dart';
import 'package:avenue/features/schdules/domain/repo/schedule_repository.dart';

class AiRepository {
  final OpenRouterHttpClient _client;
  final AiToolExecutor _executor;
  final List<Map<String, dynamic>> _history = [];
  static const int _maxHistoryMessages = 15;
  static const int _maxToolIterations = 5;

  AiRepository({
    required String apiKey,
    required ScheduleRepository scheduleRepository,
  }) : _client = OpenRouterHttpClient(apiKey: apiKey),
       _executor = AiToolExecutor(scheduleRepository);

  Future<Map<String, dynamic>> processUserMessage({
    required String userMessage,
    required String systemPrompt,
  }) async {
    // 1. Initial Call to Gemini with Search Tools
    var currentResponse = await _client.generateContent(
      systemPrompt: systemPrompt,
      history: _getRecentHistory(),
      userMessage: userMessage,
      tools: AiTools.declarations,
    );

    // 2. Loop until no more function calls or max iterations reached
    int iterations = 0;
    while (iterations < _maxToolIterations) {
      final parts = currentResponse['parts'] as List;
      final functionCalls = parts
          .where((p) => p.containsKey('functionCall'))
          .toList();

      if (functionCalls.isEmpty) break;

      // Prepare Tool Results
      final List<Map<String, dynamic>> toolResults = [];
      for (var call in functionCalls) {
        final functionCall = call['functionCall'];
        final toolName = functionCall['name'];
        final args = functionCall['args'] as Map<String, dynamic>? ?? {};

        // Execute Tool
        final result = await _executor.execute(toolName, args);

        toolResults.add({
          'functionResponse': {
            'name': toolName,
            'response': {'content': result},
          },
        });
      }

      // Add AI's intent and Tool results to history
      _history.add({
        'role': 'user',
        'parts': [
          {'text': userMessage},
        ],
      });
      _history.add({'role': 'model', 'parts': parts});
      _history.add({'role': 'function', 'parts': toolResults});

      // Call Gemini again with results
      currentResponse = await _client.generateContent(
        systemPrompt: systemPrompt,
        history: _getRecentHistory(),
        userMessage: 'Please continue based on the data provided.',
        tools: AiTools.declarations,
      );

      iterations++;
    }

    // 3. Update Final History with Text Response
    _history.add({
      'role': 'user',
      'parts': [
        {'text': userMessage},
      ],
    });
    _history.add({'role': 'model', 'parts': currentResponse['parts']});

    return currentResponse;
  }

  void clearHistory() => _history.clear();

  void loadHistory(List<Map<String, dynamic>> history) {
    _history.clear();
    _history.addAll(history);
  }

  List<Map<String, dynamic>> _getRecentHistory() {
    if (_history.length <= _maxHistoryMessages) return _history;
    return _history.sublist(_history.length - _maxHistoryMessages);
  }
}
