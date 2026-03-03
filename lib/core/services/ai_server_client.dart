import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/observability.dart';

class AiServerClient {
  final SupabaseClient _supabase;

  AiServerClient({required SupabaseClient supabase}) : _supabase = supabase;

  Future<Map<String, dynamic>> generateContent({
    required String systemPrompt,
    required List<Map<String, dynamic>> history,
    String? userMessage,
    List<Map<String, dynamic>>? tools,
    String? traceId,
  }) async {
    try {
      // --- ADAPTER: Convert Gemini Request to OpenAI Request (Existing Logic) ---
      final List<Map<String, dynamic>> messages = [];
      messages.add({'role': 'system', 'content': systemPrompt});

      for (final msg in history) {
        final role = msg['role'] == 'model' ? 'assistant' : 'user';
        final parts = (msg['parts'] as List).cast<dynamic>();

        final textPart = parts.firstWhere(
          (p) => p.containsKey('text'),
          orElse: () => null,
        );

        if (msg['role'] == 'function') {
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

        final funcCallPart = parts.firstWhere(
          (p) => p.containsKey('functionCall'),
          orElse: () => null,
        );
        if (funcCallPart != null) {
          final fc = funcCallPart['functionCall'];
          if (textPart == null) {
            messages.add({
              'role': 'assistant',
              'content':
                  'Calling tool: ${fc['name']} with args: ${jsonEncode(fc['args'])}',
            });
          }
        }
      }

      if (userMessage != null) {
        messages.add({'role': 'user', 'content': userMessage});
      }

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
        'messages': messages,
        if (openAiTools != null) 'tools': openAiTools,
      };

      AvenueLogger.log(
        event: 'AI_SERVER_REQUEST',
        layer: LoggerLayer.AI,
        traceId: traceId,
        payload: body,
      );

      // --- POINT OF CONTACT: Invoke Supabase Edge Function ---
      final response = await _supabase.functions.invoke('ask-ai', body: body);

      if (response.status != 200) {
        throw Exception(
          'Edge Function Error: ${response.status} - ${response.data}',
        );
      }

      final json = response.data;

      // --- ADAPTER: Convert OpenAI Response to Gemini Format (Existing Logic) ---
      final choice = json['choices'][0];
      final message = choice['message'];
      final content = message['content'];
      final toolCalls = message['tool_calls'] as List?;

      final List<Map<String, dynamic>> resultParts = [];

      if (content != null && content.toString().isNotEmpty) {
        resultParts.add({'text': content});
      }

      if (toolCalls != null) {
        for (var tc in toolCalls) {
          final func = tc['function'];
          resultParts.add({
            'functionCall': {
              'name': func['name'],
              'args': jsonDecode(func['arguments']),
            },
          });
        }
      }

      final geminiContent = {'parts': resultParts};

      AvenueLogger.log(
        event: 'AI_SERVER_RESPONSE',
        layer: LoggerLayer.AI,
        traceId: traceId,
        payload: geminiContent,
      );

      return geminiContent;
    } catch (e) {
      AvenueLogger.log(
        event: 'AI_SERVER_ERROR',
        layer: LoggerLayer.AI,
        level: LoggerLevel.ERROR,
        traceId: traceId,
        payload: e.toString(),
      );
      throw Exception('AI Server Client Error: ${e.toString()}');
    }
  }
}
