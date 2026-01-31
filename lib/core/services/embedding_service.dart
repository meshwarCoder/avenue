import 'package:google_generative_ai/google_generative_ai.dart';

class EmbeddingService {
  final GenerativeModel _embeddingModel;

  EmbeddingService({required String apiKey})
    : _embeddingModel = GenerativeModel(
        model: 'text-embedding-004',
        apiKey: apiKey,
      );

  /// Generates a vector embedding for the given text.
  /// Returns a list of doubles representing the embedding.
  Future<List<double>> generateEmbedding(String text) async {
    if (text.isEmpty) return [];

    try {
      final content = Content.text(text);
      final result = await _embeddingModel.embedContent(content);

      if (result.embedding.values.isEmpty) {
        throw Exception('Generated embedding is empty');
      }

      return result.embedding.values;
    } catch (e) {
      print('Failed to generate embedding: $e');
      rethrow;
    }
  }
}
