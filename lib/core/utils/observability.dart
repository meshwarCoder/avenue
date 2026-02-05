import 'dart:developer' as developer;
import 'dart:convert';

const bool kDebugObservability = true;

enum LoggerLayer { UI, STATE, AI, DB, SYNC }

enum LoggerLevel { INFO, WARN, ERROR }

class AvenueLogger {
  static void log({
    required String event,
    required LoggerLayer layer,
    LoggerLevel level = LoggerLevel.INFO,
    String? traceId,
    dynamic payload,
  }) {
    if (!kDebugObservability) return;

    final timestamp = DateTime.now().toIso8601String().substring(11, 23);
    final layerStr = layer.toString().split('.').last.padRight(5);
    final traceStr = traceId != null ? '[TRACE $traceId]' : '';

    String message = '[$layerStr] $traceStr $event';
    if (level == LoggerLevel.ERROR) {
      message = '❌ $message';
    } else if (level == LoggerLevel.WARN) {
      message = '⚠️ $message';
    }

    Map<String, dynamic> data = {
      'timestamp': timestamp,
      'layer': layer.toString(),
      'level': level.toString(),
      'event': event,
      'traceId': traceId,
    };

    if (payload != null) {
      data['payload'] = payload;
    }

    developer.log(
      message,
      name: 'Avenue',
      level: _levelToInt(level),
      time: DateTime.now(),
      error: level == LoggerLevel.ERROR ? payload : null,
    );

    // Also print to console for easier debugging in some IDEs
    print('DEBUG: $message ${payload != null ? _formatPayload(payload) : ""}');
  }

  static int _levelToInt(LoggerLevel level) {
    switch (level) {
      case LoggerLevel.INFO:
        return 0;
      case LoggerLevel.WARN:
        return 500;
      case LoggerLevel.ERROR:
        return 1000;
    }
  }

  static String _formatPayload(dynamic payload) {
    try {
      if (payload is Map || payload is List) {
        return '\n${const JsonEncoder.withIndent('  ').convert(payload)}';
      }
      return payload.toString();
    } catch (_) {
      return payload.toString();
    }
  }
}
