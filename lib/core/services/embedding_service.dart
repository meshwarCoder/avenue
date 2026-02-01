import 'dart:convert';
import 'dart:io';

class EmbeddingService {
  final String _apiKey;
  final String _model = 'text-embedding-004';
  final String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';

  EmbeddingService({required String apiKey}) : _apiKey = apiKey;

  /// Generates a vector embedding for the given text.
  /// Returns a list of doubles representing the embedding.
  Future<List<double>> generateEmbedding(String text) async {
    if (text.isEmpty) return [];

    final client = HttpClient();
    try {
      final url = Uri.parse('$_baseUrl/$_model:embedContent?key=$_apiKey');
      final request = await client.postUrl(url);
      request.headers.set('Content-Type', 'application/json');

      final body = {
        'content': {
          'parts': [
            {'text': text},
          ],
        },
      };

      request.add(utf8.encode(jsonEncode(body)));
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode != 200) {
        throw Exception(
          'Embedding API Error: ${response.statusCode} - $responseBody',
        );
      }

      final json = jsonDecode(responseBody);
      final List<dynamic> values = json['embedding']['values'];
      return values.map((e) => (e as num).toDouble()).toList();
    } catch (e) {
      print('Failed to generate embedding: $e');
      rethrow;
    } finally {
      client.close();
    }
  }
}
