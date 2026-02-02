import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/chat_model.dart';
import '../models/chat_message_model.dart';

class ChatRepository {
  final SupabaseClient _supabase;

  ChatRepository({required SupabaseClient supabase}) : _supabase = supabase;

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
      return chatId;
    } catch (e) {
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
    print('ChatRepository: Deleting chat $chatId');

    try {
      // Delete messages first (due to foreign key constraint)
      await _supabase.from('messages').delete().eq('chat_id', chatId);

      // Then delete the chat
      await _supabase.from('chats').delete().eq('id', chatId);

      print('ChatRepository: Chat deleted successfully');
    } catch (e, stackTrace) {
      print('ChatRepository.deleteChat failed!');
      print('Error: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }
}
