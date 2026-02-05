import 'dart:convert';
import 'dart:io';
import '../../../core/utils/observability.dart';

class GeminiHttpClient {
  final String apiKey;
  final String model;
  final String baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';

  GeminiHttpClient({required this.apiKey, this.model = 'gemini-flash-latest'});

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
    AvenueLogger.log(
      event: 'AI_HISTORY_WINDOW',
      layer: LoggerLayer.AI,
      traceId: traceId,
      payload: history,
    );

    final client = HttpClient();
    try {
      final url = Uri.parse('$baseUrl/$model:generateContent?key=$apiKey');
      final request = await client.postUrl(url);
      request.headers.set('Content-Type', 'application/json');

      final v1betaBody = {
        'contents': [
          ...history,
          if (userMessage != null)
            {
              'role': 'user',
              'parts': [
                {'text': userMessage},
              ],
            },
        ],
        'system_instruction': {
          'parts': [
            {'text': systemPrompt},
          ],
        },
        if (tools != null && tools.isNotEmpty)
          'tools': [
            {'function_declarations': tools},
          ],
        'tool_config': {
          'function_calling_config': {'mode': 'AUTO'},
        },
      };

      AvenueLogger.log(
        event: 'AI_PAYLOAD_SENT',
        layer: LoggerLayer.AI,
        traceId: traceId,
        payload: v1betaBody,
      );

      request.add(utf8.encode(jsonEncode(v1betaBody)));

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode != 200) {
        throw Exception(
          'Gemini API Error: ${response.statusCode} - $responseBody',
        );
      }

      final json = jsonDecode(responseBody);

      try {
        final candidate = json['candidates'][0];
        final content = candidate['content'];

        // Safety check: sometimes content is null if finishReason is SAFETY/recitation
        if (content == null) {
          final finishReason = candidate['finishReason'];
          throw Exception(
            'Gemini blocked response. FinishReason: $finishReason',
          );
        }

        if (content['parts'] == null) {
          throw Exception('Gemini response missing "parts". Content: $content');
        }

        AvenueLogger.log(
          event: 'AI_RESPONSE_RECEIVED',
          layer: LoggerLayer.AI,
          traceId: traceId,
          payload: content,
        );

        return content;
      } catch (e) {
        AvenueLogger.log(
          event: 'AI_ERROR',
          layer: LoggerLayer.AI,
          level: LoggerLevel.ERROR,
          traceId: traceId,
          payload: e.toString(),
        );
        throw Exception('Unexpected response format: ${e.toString()}');
      }
    } finally {
      client.close();
    }
  }
}
