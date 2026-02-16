import 'dart:convert';
import 'dart:io';
import '../utils/observability.dart';

class EmbeddingService {
  final String _apiKey;
  // Using a Google model via OpenRouter to maintain 768 dimensions if possible
  final String _model = 'google/gemini-embedding-001';
  final String _baseUrl = 'https://openrouter.ai/api/v1/embeddings';

  EmbeddingService({required String apiKey}) : _apiKey = apiKey;

  /// Generates a vector embedding for the given text.
  /// Returns a list of doubles representing the embedding.
  Future<List<double>> generateEmbedding(String text) async {
    if (text.isEmpty) return [];

    final client = HttpClient();
    try {
      final url = Uri.parse(_baseUrl);
      final request = await client.postUrl(url);
      request.headers.set('Content-Type', 'application/json');
      request.headers.set('Authorization', 'Bearer $_apiKey');
      request.headers.set('HTTP-Referer', 'https://avenue-app.com');
      request.headers.set('X-Title', 'Avenue');

      final body = {'model': _model, 'input': text};

      request.add(utf8.encode(jsonEncode(body)));
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode != 200) {
        AvenueLogger.log(
          event: 'EMBEDDING_ERROR',
          level: LoggerLevel.ERROR,
          layer: LoggerLayer.SYNC,
          payload:
              'OpenRouter Embedding Error: ${response.statusCode} - $responseBody',
        );
        return [];
      }

      final json = jsonDecode(responseBody) as Map<String, dynamic>;
      // OpenAI format: { data: [ { embedding: [...] } ] }
      if (json.containsKey('data')) {
        final data = json['data'] as List;
        if (data.isNotEmpty) {
          final first = data[0];
          final embedding = List<double>.from(first['embedding']);
          return embedding;
        }
      }

      // Fallback or error
      return [];
    } catch (e) {
      AvenueLogger.log(
        event: 'EMBEDDING_ERROR',
        level: LoggerLevel.ERROR,
        layer: LoggerLayer.SYNC,
        payload: e.toString(),
      );
      // Don't rethrow to avoid crashing UI, just return empty for sync skip
      return [];
    } finally {
      client.close();
    }
  }
}
