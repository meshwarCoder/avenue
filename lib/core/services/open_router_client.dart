import 'dart:convert';
import 'dart:io';
import '../utils/observability.dart';

class OpenRouterClient {
  String apiKey;
  String model;
  final String baseUrl = 'https://openrouter.ai/api/v1/chat/completions';

  OpenRouterClient({
    required this.apiKey,
    this.model = 'google/gemini-3-pro-preview',
  });

  Future<Map<String, dynamic>> generateContent({
    required String systemPrompt,
    required List<Map<String, dynamic>> history,
    String? userMessage,
    List<Map<String, dynamic>>? tools,
    String? traceId,
  }) async {
    AvenueLogger.log(
      event: 'AI_SYSTEM_PROMPT',
      layer: LoggerLayer.AI,
      traceId: traceId,
      payload: systemPrompt,
    );

    final client = HttpClient();
    try {
      final url = Uri.parse(baseUrl);
      final request = await client.postUrl(url);
      request.headers.set('Content-Type', 'application/json');
      request.headers.set('Authorization', 'Bearer $apiKey');
      request.headers.set('HTTP-Referer', 'https://avenue-app.com'); // Optional
      request.headers.set('X-Title', 'Avenue'); // Optional

      // --- ADAPTER: Convert Gemini Request to OpenAI Request ---

      final List<Map<String, dynamic>> messages = [];

      // 1. System Prompt
      messages.add({'role': 'system', 'content': systemPrompt});

      // 2. History
      for (final msg in history) {
        final role = msg['role'] == 'model' ? 'assistant' : 'user';
        final parts = (msg['parts'] as List).cast<dynamic>();
        // Text content
        final textPart = parts.firstWhere(
          (p) => p.containsKey('text'),
          orElse: () => null,
        );

        if (msg['role'] == 'function') {
          // Function Result
          // OpenRouter/OpenAI expects:
          // role: tool
          // tool_call_id: ... (We don't track this in Gemini history easily, fallback needed)
          // name: ...
          // content: result

          // Since we don't have tool_call_ids in the old history format,
          // we might need to skip or approximate.
          // Ideally, we treat 'function' role as a user message with tool results?
          // Or we just append it as text for context if we can't map perfectly.

          // Simplification: Append as user message for context "Tool [name] output: ..."
          // This is imperfect but usually works for models.
          // OR: Since we are moving forward, we can try to map correctly if possible.
          // But existing 'function' history structure is:
          // [{'functionResponse': {'name': '...', 'response': {'content': ...}}}]

          for (var part in parts) {
            if (part.containsKey('functionResponse')) {
              final fr = part['functionResponse'];
              final name = fr['name'];
              final content = jsonEncode(fr['response']['content']);
              messages.add({
                'role': 'user',
                'content': 'Tool Output ($name): $content',
              });
            }
          }
          continue;
        }

        if (textPart != null) {
          messages.add({'role': role, 'content': textPart['text']});
        }

        // Handle previous function CALLS in history (from model)
        // Gemini history stores: parts: [{'functionCall': ...}]
        // We'll convert these to text representations for simplicity in migration
        // unless we strictly need tool_calls history.
        // Given we are switching providers, 'tool_calls' history might cause ID mismatches anyway.
        // Best approach: Convert old function calls to text description "I will call tool X..."
        final funcCallPart = parts.firstWhere(
          (p) => p.containsKey('functionCall'),
          orElse: () => null,
        );
        if (funcCallPart != null) {
          final fc = funcCallPart['functionCall'];
          // We already added text above if it existed.
          // If model only called function, we need an assistant message.
          if (textPart == null) {
            messages.add({
              'role': 'assistant',
              'content':
                  'Calling tool: ${fc['name']} with args: ${jsonEncode(fc['args'])}',
            });
          } else {
            // Append to last assistant message
            // messages.last['content'] += ...
          }
        }
      }

      // 3. Current User Message
      if (userMessage != null) {
        messages.add({'role': 'user', 'content': userMessage});
      }

      // 4. Tools Adapter
      List<Map<String, dynamic>>? openAiTools;
      if (tools != null && tools.isNotEmpty) {
        openAiTools = tools.map((t) {
          return {
            'type': 'function',
            'function': {
              'name': t['name'],
              'description': t['description'],
              'parameters': t['parameters'],
            },
          };
        }).toList();
      }

      final body = {
        'model': model,
        'messages': messages,
        if (openAiTools != null) 'tools': openAiTools,
      };

      AvenueLogger.log(
        event: 'AI_PAYLOAD_SENT',
        layer: LoggerLayer.AI,
        traceId: traceId,
        payload: body,
      );

      request.add(utf8.encode(jsonEncode(body)));

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode != 200) {
        throw Exception(
          'OpenRouter API Error: ${response.statusCode} - $responseBody',
        );
      }

      final json = jsonDecode(responseBody);
      final choice = json['choices'][0];
      final message = choice['message'];
      final content = message['content'];
      final toolCalls = message['tool_calls'] as List?;

      // --- ADAPTER: Convert OpenAI Response to Gemini Format for Repository ---
      // Expected by Repository: {'parts': [...]}
      // Text Part: {'text': ...}
      // Function Call Part: {'functionCall': {'name': ..., 'args': ...}}

      final List<Map<String, dynamic>> parts = [];

      if (content != null && content.toString().isNotEmpty) {
        parts.add({'text': content});
      }

      if (toolCalls != null) {
        for (var tc in toolCalls) {
          final func = tc['function'];
          parts.add({
            'functionCall': {
              'name': func['name'],
              'args': jsonDecode(func['arguments']),
            },
          });
        }
      }

      final geminiContent = {'parts': parts};

      AvenueLogger.log(
        event: 'AI_RESPONSE_RECEIVED',
        layer: LoggerLayer.AI,
        traceId: traceId,
        payload: geminiContent,
      );

      return geminiContent;
    } catch (e) {
      AvenueLogger.log(
        event: 'AI_ERROR',
        layer: LoggerLayer.AI,
        level: LoggerLevel.ERROR,
        traceId: traceId,
        payload: e.toString(),
      );
      throw Exception('OpenRouter Client Error: ${e.toString()}');
    } finally {
      client.close();
    }
  }
}
