import 'dart:convert';
import 'ai_action_models.dart';

class AiResponseParser {
  static (String message, List<AiAction> actions, String? suggestedTitle) parse(
    String response,
  ) {
    try {
      // 1. Try to find JSON block, handling potential markdown markers
      String jsonStr = response.trim();

      // Remove markdown code block markers if present
      if (jsonStr.contains('```json')) {
        final start = jsonStr.indexOf('```json') + 7;
        final end = jsonStr.lastIndexOf('```');
        if (end > start) {
          jsonStr = jsonStr.substring(start, end).trim();
        }
      } else if (jsonStr.contains('```')) {
        final start = jsonStr.indexOf('```') + 3;
        final end = jsonStr.lastIndexOf('```');
        if (end > start) {
          jsonStr = jsonStr.substring(start, end).trim();
        }
      }

      // If it still doesn't look like JSON, try to find the first { and last }
      if (!jsonStr.startsWith('{')) {
        final start = jsonStr.indexOf('{');
        final end = jsonStr.lastIndexOf('}');
        if (start != -1 && end != -1 && end > start) {
          jsonStr = jsonStr.substring(start, end + 1);
        }
      }

      final decoded = jsonDecode(jsonStr);

      if (decoded is Map<String, dynamic>) {
        final message = decoded['message'] as String? ?? '';
        final actionsRaw = decoded['actions'] as List<dynamic>? ?? [];
        final suggestedTitle = decoded['suggested_chat_title'] as String?;

        final actions = actionsRaw.map((a) {
          try {
            return AiAction.fromJson(a as Map<String, dynamic>);
          } catch (e) {
            print('Error parsing individual action: $e');
            return AiAction.unknown(rawResponse: a.toString());
          }
        }).toList();

        return (message, actions, suggestedTitle);
      }
    } catch (e) {
      print('Error parsing AI response: $e');
      print('Raw response was: $response');
    }

    // Default: return the whole response as a message with no actions
    return (response, <AiAction>[], null);
  }
}
