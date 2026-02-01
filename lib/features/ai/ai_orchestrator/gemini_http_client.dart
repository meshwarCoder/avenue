import 'dart:convert';
import 'dart:io';

class GeminiHttpClient {
  final String apiKey;
  final String model;
  final String baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';

  GeminiHttpClient({required this.apiKey, this.model = 'gemini-flash-latest'});

  Future<String> generateContent({
    required String systemPrompt,
    required List<Map<String, dynamic>> history,
    required String userMessage,
  }) async {
    final client = HttpClient();
    try {
      final url = Uri.parse('$baseUrl/$model:generateContent?key=$apiKey');
      final request = await client.postUrl(url);
      request.headers.set('Content-Type', 'application/json');

      final cleanContents = [
        ...history,
        {
          'role': 'user',
          'parts': [
            {
              'text':
                  "Instructions:\n$systemPrompt\n\nUser Message: $userMessage",
            },
          ],
        },
      ];

      final v1betaBody = {
        'contents': cleanContents,
        'system_instruction': {
          'parts': [
            {'text': systemPrompt},
          ],
        },
      };

      request.add(utf8.encode(jsonEncode(v1betaBody)));

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode != 200) {
        throw Exception(
          'Gemini API Error: ${response.statusCode} - $responseBody',
        );
      }

      final json = jsonDecode(responseBody);

      // Extract text from candidates
      try {
        final text =
            json['candidates'][0]['content']['parts'][0]['text'] as String;
        return text;
      } catch (e) {
        throw Exception('Unexpected response format: $responseBody');
      }
    } finally {
      client.close();
    }
  }
}
