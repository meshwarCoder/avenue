import 'dart:convert';

import 'ai_action_models.dart';
import '../../../core/utils/observability.dart';

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
        final suggestedTitle = decoded['suggested_chat_title'] as String?;

        List<AiAction> actions = [];
        try {
          final actionsList = decoded['actions'] as List? ?? [];
          actions = actionsList.map((a) {
            try {
              final map = Map<String, dynamic>.from(a as Map);
              // Normalize type to match AiAction union keys
              // Model now expects 'createTask', 'updateTask', 'deleteTask'
              if (map['type'] == 'addTask') {
                map['type'] = 'createTask';
              } else if (map['type'] == 'addDefaultTask') {
                map['type'] = 'createDefaultTask';
              }
              return AiAction.fromJson(map);
            } catch (e) {
              AvenueLogger.log(
                event: 'AI_PARSE_ERROR',
                level: LoggerLevel.WARN,
                layer: LoggerLayer.AI,
                payload: 'Single action parse error: $e',
              );
              return const AiAction.unknown(
                rawResponse: 'Invalid action format',
              );
            }
          }).toList();
        } catch (e) {
          AvenueLogger.log(
            event: 'AI_PARSE_ERROR',
            level: LoggerLevel.WARN,
            layer: LoggerLayer.AI,
            payload: 'Actions list parse error: $e',
          );
        }

        return (message, actions, suggestedTitle);
      }
    } catch (e) {
      AvenueLogger.log(
        event: 'AI_PARSE_ERROR',
        level: LoggerLevel.ERROR,
        layer: LoggerLayer.AI,
        payload: {'error': e.toString(), 'rawResponse': response},
      );
      return (response, [], null);
    }

    // Default: return the whole response as a message with no actions
    return (response, <AiAction>[], null);
  }
}
