import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../schdules/data/models/task_model.dart';
import '../../schdules/domain/repo/schedule_repository.dart';
import 'ai_tools.dart';

class AiRepository {
  final String _apiKey;
  final List<Map<String, dynamic>> _history = [];
  final ScheduleRepository _scheduleRepository;
  final String _modelName = 'gemini-3-flash-preview';
  final String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';

  AiRepository({
    required String apiKey,
    required ScheduleRepository scheduleRepository,
  }) : _apiKey = apiKey,
       _scheduleRepository = scheduleRepository {
    // Initialize history with system prompt
    _history.add({
      'role': 'system',
      'parts': [
        {
          'text':
              'You are a helpful assistant for a Task Management App. '
              'Use the available tools to manage tasks. '
              'Tasks have an "importance_type" attribute which can be "Low", "Medium", or "High". '
              'If you need to know the date, assume the user means relative to ${DateTime.now().toIso8601String()}. '
              'Always confirm actions with a short message.',
        },
      ],
    });
  }

  Future<String> sendMessage(String message) async {
    // 1. Add user message to history
    _history.add({
      'role': 'user',
      'parts': [
        {'text': message},
      ],
    });

    // 2. Generate initial response
    var responseJson = await _generateContentRaw();
    _addTurnToHistory(responseJson);

    // 3. Tool Loop
    int loopLimit = 5;
    while (_hasFunctionCalls(responseJson) && loopLimit > 0) {
      loopLimit--;
      final functionCalls = _getFunctionCalls(responseJson);
      final toolResponseParts = <Map<String, dynamic>>[];

      for (final call in functionCalls) {
        final name = call['name'] as String;
        final args = Map<String, dynamic>.from(call['args'] as Map);
        final signature = call['thought_signature'] as String?;

        print('AI calling tool: $name with args: $args');
        final result = await _handleToolCallInternal(name, args);
        print('Tool $name result: $result');

        final responsePart = {
          'functionResponse': {
            'name': name,
            'response': result,
            if (signature != null) 'thought_signature': signature,
          },
        };
        toolResponseParts.add(responsePart);
      }

      // Add tool results to history
      _history.add({'role': 'user', 'parts': toolResponseParts});

      // Call model again with updated history
      responseJson = await _generateContentRaw();
      _addTurnToHistory(responseJson);
    }

    final text = _extractText(responseJson);
    print('AI Response: $text');
    return text ?? "I'm not sure how to help with that.";
  }

  Future<Map<String, dynamic>> _generateContentRaw() async {
    final url = '$_baseUrl/$_modelName:generateContent?key=$_apiKey';

    // Convert AiTools to JSON
    final toolsJson = AiTools.tools.map((t) => t.toJson()).toList();

    final requestBody = {'contents': _history, 'tools': toolsJson};

    final client = HttpClient();
    try {
      final request = await client.postUrl(Uri.parse(url));
      request.headers.set('Content-Type', 'application/json');
      request.add(utf8.encode(jsonEncode(requestBody)));

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode != 200) {
        print('Gemini API Error: ${response.statusCode} - $responseBody');
        throw Exception('Gemini API Error: $responseBody');
      }

      return jsonDecode(responseBody) as Map<String, dynamic>;
    } finally {
      client.close();
    }
  }

  void _addTurnToHistory(Map<String, dynamic> responseJson) {
    try {
      final candidates = responseJson['candidates'] as List<dynamic>;
      if (candidates.isEmpty) return;
      final candidate = candidates.first as Map<String, dynamic>;
      final content = candidate['content'] as Map<String, dynamic>;

      // Crucial: Add the EXACT content from the API to history to preserve all fields
      _history.add({
        'role': content['role'] ?? 'model',
        'parts': content['parts'] as List<dynamic>,
      });
    } catch (e) {
      print('Error adding turn to history: $e');
    }
  }

  bool _hasFunctionCalls(Map<String, dynamic> responseJson) {
    try {
      final candidates = responseJson['candidates'] as List<dynamic>?;
      if (candidates == null || candidates.isEmpty) return false;
      final content = candidates.first['content'] as Map<String, dynamic>;
      final parts = content['parts'] as List<dynamic>;
      return parts.any((p) => (p as Map).containsKey('functionCall'));
    } catch (e) {
      print('Error checking for function calls: $e');
      return false;
    }
  }

  List<Map<String, dynamic>> _getFunctionCalls(
    Map<String, dynamic> responseJson,
  ) {
    try {
      final candidates = responseJson['candidates'] as List<dynamic>;
      final content = candidates.first['content'] as Map<String, dynamic>;
      final parts = content['parts'] as List<dynamic>;
      return parts
          .where((p) => (p as Map).containsKey('functionCall'))
          .map((p) => Map<String, dynamic>.from(p['functionCall'] as Map))
          .toList();
    } catch (e) {
      print('Error extracting function calls: $e');
      return [];
    }
  }

  String? _extractText(Map<String, dynamic> responseJson) {
    try {
      final candidates = responseJson['candidates'] as List<dynamic>?;
      if (candidates == null || candidates.isEmpty) return null;
      final content = candidates.first['content'] as Map<String, dynamic>;
      final parts = content['parts'] as List<dynamic>;
      final textParts = parts.where((p) => (p as Map).containsKey('text'));
      if (textParts.isEmpty) return null;
      return textParts.map((p) => p['text']).join('\n');
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>> _handleToolCallInternal(
    String name,
    Map<String, dynamic> args,
  ) async {
    try {
      switch (name) {
        case 'getTasks':
          final startDate = DateTime.parse(args['startDate'] as String);
          final result = await _scheduleRepository.getTasksByDate(startDate);
          return result.fold(
            (failure) => {'error': failure.message},
            (tasks) => {
              'tasks': tasks.map((t) => t.toSupabaseJson('user')).toList(),
            },
          );

        case 'addTask':
          final taskData = Map<String, dynamic>.from(args);
          final task = TaskModel.fromSupabaseJson({
            ...taskData,
            'id': null,
            'user_id': 'user',
            'completed': false,
            'is_deleted': false,
          });
          final result = await _scheduleRepository.addTask(task);
          return result.fold(
            (failure) => {'error': failure.message},
            (_) => {'status': 'success', 'task': task.name},
          );

        case 'updateTask':
          final id = args['id'] as String;
          final fetchResult = await _scheduleRepository.getTaskById(id);

          return await fetchResult.fold(
            (failure) async => {'error': failure.message},
            (existingTask) async {
              if (existingTask == null) return {'error': 'Task not found'};
              final currentMap = existingTask.toSupabaseJson('user');
              final newMap = {
                ...currentMap,
                ...Map<String, dynamic>.from(args),
              };

              final updatedTask = TaskModel.fromSupabaseJson(newMap);
              final updateResult = await _scheduleRepository.updateTask(
                updatedTask,
              );

              return updateResult.fold(
                (failure) => {'error': failure.message},
                (_) => {'status': 'success'},
              );
            },
          );

        case 'deleteTask':
          final id = args['id'] as String;
          final result = await _scheduleRepository.deleteTask(id);
          return result.fold(
            (failure) => {'error': failure.message},
            (_) => {'status': 'success'},
          );

        case 'searchTasks':
          final query = args['query'] as String;
          final result = await _scheduleRepository.searchTasks(query);
          return result.fold(
            (failure) => {'error': failure.message},
            (tasks) => {
              'tasks': tasks.map((t) => t.toSupabaseJson('user')).toList(),
            },
          );

        case 'searchDefaultTasks':
          final query = args['query'] as String;
          final result = await _scheduleRepository.searchDefaultTasks(query);
          return result.fold(
            (failure) => {'error': failure.message},
            (tasks) => {
              'default_tasks': tasks
                  .map((t) => t.toSupabaseJson('user'))
                  .toList(),
            },
          );

        default:
          final error = 'Unknown tool $name';
          print('Error: $error');
          return {'error': error};
      }
    } catch (e, stack) {
      print('Failed to execute $name: $e');
      print(stack);
      return {'error': 'Failed to execute $name: $e'};
    }
  }
}
