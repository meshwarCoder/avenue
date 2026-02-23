import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sqflite/sqflite.dart';
import '../models/chat_model.dart';
import '../models/chat_message_model.dart';
import '../../../../core/utils/observability.dart';
import '../../../../core/services/database_service.dart';
import '../../ai/ai_action_models.dart';

class ChatRepository {
  final SupabaseClient _supabase;
  final DatabaseService _databaseService;

  ChatRepository({
    required SupabaseClient supabase,
    required DatabaseService databaseService,
  }) : _supabase = supabase,
       _databaseService = databaseService;

  // Create a new chat session
  Future<String> createChat(String userId) async {
    try {
      final now = DateTime.now().toIso8601String();
      final response = await _supabase
          .from('chats')
          .insert({
            'user_id': userId,
            'title': 'New Chat',
            'created_at': now,
            'updated_at': now,
          })
          .select('id')
          .single();

      final chatId = response['id'] as String;
      AvenueLogger.log(
        event: 'DB_CREATE',
        layer: LoggerLayer.DB,
        payload: {'entity': 'chat', 'id': chatId, 'userId': userId},
      );
      return chatId;
    } catch (e) {
      AvenueLogger.log(
        event: 'DB_ERROR',
        level: LoggerLevel.ERROR,
        layer: LoggerLayer.DB,
        payload: 'createChat failed: $e',
      );
      rethrow;
    }
  }

  // Get all chats for a user
  Future<List<ChatModel>> getUserChats(String userId) async {
    final response = await _supabase
        .from('chats')
        .select()
        .eq('user_id', userId)
        .order('updated_at', ascending: false); // Order by Last Activity

    return (response as List).map((json) => ChatModel.fromJson(json)).toList();
  }

  // Get all messages for a specific chat
  Future<List<ChatMessageModel>> getChatMessages(String chatId) async {
    final response = await _supabase
        .from('messages')
        .select()
        .eq('chat_id', chatId)
        .order('created_at', ascending: true);

    return (response as List)
        .map((json) => ChatMessageModel.fromJson(json))
        .toList();
  }

  // Save a message to a chat
  Future<void> saveMessage({
    required String chatId,
    required String role,
    required String content,
  }) async {
    try {
      final now = DateTime.now().toIso8601String();

      // 1. Insert the message
      await _supabase.from('messages').insert({
        'chat_id': chatId,
        'role': role,
        'content': content,
        'created_at': now,
      });

      // 2. Update the chat's updated_at timestamp (Last Activity)
      await _supabase
          .from('chats')
          .update({'updated_at': now})
          .eq('id', chatId);
    } catch (e) {
      rethrow;
    }
  }

  // Update chat title
  Future<void> updateChatTitle(String chatId, String title) async {
    // Update title AND timestamp
    await _supabase
        .from('chats')
        .update({
          'title': title,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', chatId);

    // Note: Removed .select() check as per previous fix request to avoid RLS 406 error.
    // Assuming silent success or exception from SDK.
  }

  // Delete a chat and its messages
  Future<void> deleteChat(String chatId) async {
    AvenueLogger.log(
      event: 'DB_DELETE',
      layer: LoggerLayer.DB,
      payload: {'entity': 'chat', 'id': chatId},
    );

    try {
      // Delete messages first (due to foreign key constraint)
      await _supabase.from('messages').delete().eq('chat_id', chatId);

      // Then delete the chat
      await _supabase.from('chats').delete().eq('id', chatId);

      AvenueLogger.log(
        event: 'DB_RESULT',
        layer: LoggerLayer.DB,
        payload: 'Chat deleted successfully',
      );
    } catch (e) {
      AvenueLogger.log(
        event: 'DB_ERROR',
        level: LoggerLevel.ERROR,
        layer: LoggerLayer.DB,
        payload: 'deleteChat failed: $e',
      );
      rethrow;
    }
  }

  // --- LOCAL PENDING ACTIONS ---

  Future<void> savePendingActions(
    String chatId,
    String messageText,
    List<AiAction> actions,
  ) async {
    try {
      final db = await _databaseService.database;
      final actionsJson = jsonEncode(actions.map((a) => a.toJson()).toList());

      await db.insert('ai_pending_actions', {
        'id': '${chatId}_${messageText.hashCode}',
        'chat_id': chatId,
        'message_text': messageText,
        'actions_json': actionsJson,
        'created_at': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      AvenueLogger.log(
        event: 'DB_CREATE',
        layer: LoggerLayer.DB,
        payload: {
          'entity': 'pending_actions',
          'chatId': chatId,
          'count': actions.length,
        },
      );
    } catch (e) {
      AvenueLogger.log(
        event: 'DB_ERROR',
        level: LoggerLevel.ERROR,
        layer: LoggerLayer.DB,
        payload: 'savePendingActions failed: $e',
      );
    }
  }

  Future<Map<String, List<AiAction>>> getPendingActions(String chatId) async {
    try {
      final db = await _databaseService.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'ai_pending_actions',
        where: 'chat_id = ?',
        whereArgs: [chatId],
      );

      final result = <String, List<AiAction>>{};
      for (final map in maps) {
        final text = map['message_text'] as String;
        final jsonStr = map['actions_json'] as String;
        final List<dynamic> list = jsonDecode(jsonStr);
        final actions = list.map((item) => AiAction.fromJson(item)).toList();
        result[text] = actions;
      }
      return result;
    } catch (e) {
      return {};
    }
  }

  Future<void> deletePendingActions(String chatId, String messageText) async {
    try {
      final db = await _databaseService.database;
      await db.delete(
        'ai_pending_actions',
        where: 'chat_id = ? AND message_text = ?',
        whereArgs: [chatId, messageText],
      );
    } catch (e) {
      // Ignore
    }
  }
}
