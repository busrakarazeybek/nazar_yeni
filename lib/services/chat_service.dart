import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/message.dart';
import './supabase_service.dart';

class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  final SupabaseService _supabaseService = SupabaseService();
  StreamSubscription<List<Map<String, dynamic>>>? _messagesSubscription;

  /// Get or create conversation for a match
  Future<String> getOrCreateConversation(String matchId) async {
    try {
      final client = await _supabaseService.client;

      // Try to find existing conversation
      final existingConversation = await client
          .from('conversations')
          .select('id')
          .eq('match_id', matchId)
          .maybeSingle();

      if (existingConversation != null) {
        return existingConversation['id'] as String;
      }

      // Create new conversation
      final newConversation = await client
          .from('conversations')
          .insert({
            'match_id': matchId,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select('id')
          .single();

      return newConversation['id'] as String;
    } catch (error) {
      throw Exception('Failed to get or create conversation: $error');
    }
  }

  /// Send a message
  Future<Message> sendMessage({
    required String conversationId,
    required String senderId,
    required String content,
    String? messageType = 'text',
  }) async {
    try {
      final client = await _supabaseService.client;

      final response = await client
          .from('messages')
          .insert({
            'conversation_id': conversationId,
            'sender_id': senderId,
            'content': content,
            'message_type': messageType,
            'is_read': false,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      return Message.fromJson(response);
    } catch (error) {
      throw Exception('Failed to send message: $error');
    }
  }

  /// Get messages for a conversation
  Future<List<Message>> getMessages(
    String conversationId, {
    int limit = 50,
    String? before,
  }) async {
    try {
      final client = await _supabaseService.client;

      final response = await client
          .from('messages')
          .select()
          .eq('conversation_id', conversationId)
          .order('created_at', ascending: false)
          .limit(limit);

      return response
          .map((json) => Message.fromJson(json))
          .toList()
          .reversed
          .toList();
    } catch (error) {
      throw Exception('Failed to get messages: $error');
    }
  }

  /// Stream messages for real-time updates
  Stream<List<Message>> streamMessages(String conversationId) {
    return _supabaseService.syncClient
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true)
        .map((data) => data.map((json) => Message.fromJson(json)).toList());
  }

  /// Stream messages for a match (gets conversation ID first)
  Stream<List<Message>> streamMessagesForMatch(String matchId) async* {
    try {
      final conversationId = await getOrCreateConversation(matchId);
      yield* streamMessages(conversationId);
    } catch (error) {
      yield [];
    }
  }

  /// Mark messages as read (simplified - only for local state management)
  Future<void> markMessagesAsRead(String conversationId, String userId) async {
    // For now, we'll handle read state purely on the client side
    // The message badges will be managed by the matches screen local state
    print('🔥 CHAT_SERVICE: Marking conversation as read locally: $conversationId');
  }

  /// Get unread message count for a user
  Future<int> getUnreadMessageCount(String userId) async {
    try {
      final client = await _supabaseService.client;

      // Get all messages where user is not the sender and message is unread
      final unreadMessages = await client
          .from('messages')
          .select('id')
          .neq('sender_id', userId)
          .eq('is_read', false);

      return unreadMessages.length;
    } catch (error) {
      throw Exception('Failed to get unread message count: $error');
    }
  }

  /// Get conversations for a user
  Future<List<Map<String, dynamic>>> getConversations(String userId) async {
    try {
      final client = await _supabaseService.client;

      // Get matches where user is participant and both sides accepted
      final matches = await client
          .from('matches')
          .select('''
            id,
            candidate_id,
            target_candidate_id,
            selector_id,
            status,
            target_status,
            created_at,
            updated_at
          ''')
          .or('candidate_id.eq.$userId,target_candidate_id.eq.$userId,selector_id.eq.$userId')
          .eq('status', 'accepted')
          .eq('target_status', 'accepted');

      if (matches.isEmpty) {
        return [];
      }

      // Get all conversation IDs for these matches
      final matchIds = matches.map((m) => m['id'] as String).toList();
      final conversations = await client
          .from('conversations')
          .select('id, match_id')
          .inFilter('match_id', matchIds);

      // Create conversation map
      final conversationMap = <String, String>{};
      for (final conv in conversations) {
        conversationMap[conv['match_id'] as String] = conv['id'] as String;
      }

      // Get all conversation IDs
      final conversationIds = conversationMap.values.toList();

      if (conversationIds.isEmpty) {
        return [];
      }

      // Batch get latest messages for all conversations
      final latestMessagesQuery = await client
          .from('messages')
          .select('conversation_id, content, sender_id, created_at')
          .inFilter('conversation_id', conversationIds)
          .order('created_at', ascending: false);

      // Group latest messages by conversation
      final latestMessagesMap = <String, Map<String, dynamic>>{};
      for (final msg in latestMessagesQuery) {
        final convId = msg['conversation_id'] as String;
        if (!latestMessagesMap.containsKey(convId)) {
          latestMessagesMap[convId] = msg;
        }
      }

      // Batch get unread counts for all conversations
      print('🔥 CHAT_SERVICE: Querying unread messages for conversations: $conversationIds');
      final unreadMessagesQuery = await client
          .from('messages')
          .select('conversation_id, id, is_read, sender_id')
          .inFilter('conversation_id', conversationIds)
          .neq('sender_id', userId)
          .eq('is_read', false);
      print('🔥 CHAT_SERVICE: Found ${unreadMessagesQuery.length} unread messages');

      // Count unread messages per conversation
      final unreadCountMap = <String, int>{};
      for (final msg in unreadMessagesQuery) {
        final convId = msg['conversation_id'] as String;
        unreadCountMap[convId] = (unreadCountMap[convId] ?? 0) + 1;
      }

      // Get all partner IDs
      final partnerIds = <String>{};
      for (final match in matches) {
        if (match['candidate_id'] == userId) {
          partnerIds.add(match['target_candidate_id'] as String);
        } else if (match['target_candidate_id'] == userId) {
          partnerIds.add(match['candidate_id'] as String);
        } else if (match['selector_id'] == userId) {
          partnerIds.add(match['candidate_id'] as String);
        }
      }

      // Batch get partner profiles
      final partnerProfiles = await client
          .from('user_profiles')
          .select('id, full_name, image_url')
          .inFilter('id', partnerIds.toList());

      // Create partner profile map
      final partnerProfileMap = <String, Map<String, dynamic>>{};
      for (final profile in partnerProfiles) {
        partnerProfileMap[profile['id'] as String] = profile;
      }

      List<Map<String, dynamic>> conversationsWithMessages = [];

      for (var match in matches) {
        try {
          final matchId = match['id'] as String;
          final conversationId = conversationMap[matchId];

          if (conversationId == null) {
            continue;
          }

          // Determine partner info
          String? partnerId;
          if (match['candidate_id'] == userId) {
            partnerId = match['target_candidate_id'] as String;
          } else if (match['target_candidate_id'] == userId) {
            partnerId = match['candidate_id'] as String;
          } else if (match['selector_id'] == userId) {
            partnerId = match['candidate_id'] as String;
          }

          String partnerName = 'Bilinmeyen Kullanıcı';
          String? partnerImageUrl;

          if (partnerId != null && partnerProfileMap.containsKey(partnerId)) {
            final profile = partnerProfileMap[partnerId]!;
            partnerName =
                profile['full_name'] as String? ?? 'Bilinmeyen Kullanıcı';
            partnerImageUrl = profile['image_url'] as String?;
          }

          conversationsWithMessages.add({
            'match_id': matchId,
            'conversation_id': conversationId,
            'partner_id': partnerId,
            'partner_name': partnerName,
            'partner_image_url': partnerImageUrl,
            'latest_message': latestMessagesMap[conversationId],
            'unread_count': unreadCountMap[conversationId] ?? 0,
            'match_date': match['updated_at'] ?? match['created_at'],
          });
        } catch (e) {
          print('Error processing match ${match['id']}: $e');
          continue;
        }
      }

      // Sort by latest activity (either latest message or match date)
      conversationsWithMessages.sort((a, b) {
        final aTime = a['latest_message'] != null
            ? DateTime.parse(a['latest_message']['created_at'])
            : DateTime.parse(a['match_date']);
        final bTime = b['latest_message'] != null
            ? DateTime.parse(b['latest_message']['created_at'])
            : DateTime.parse(b['match_date']);
        return bTime.compareTo(aTime);
      });

      return conversationsWithMessages;
    } catch (error) {
      throw Exception('Failed to get conversations: $error');
    }
  }

  /// Delete a message (soft delete)
  Future<void> deleteMessage(String messageId) async {
    try {
      final client = await _supabaseService.client;

      await client.from('messages').update({
        'deleted_at': DateTime.now().toIso8601String(),
        'content': 'Bu mesaj silindi',
      }).eq('id', messageId);
    } catch (error) {
      throw Exception('Failed to delete message: $error');
    }
  }

  /// Check if user can send messages in this match
  Future<bool> canSendMessage(String matchId, String userId) async {
    try {
      final client = await _supabaseService.client;

      final match = await client.from('matches').select('''
            candidate_id,
            target_candidate_id,
            selector_id,
            status,
            target_status
          ''').eq('id', matchId).single();

      // Check if user is participant in the match
      final isParticipant = match['candidate_id'] == userId ||
          match['target_candidate_id'] == userId ||
          match['selector_id'] == userId;

      // Check if match is active (both sides accepted)
      final isActive =
          match['status'] == 'accepted' && match['target_status'] == 'accepted';

      return isParticipant && isActive;
    } catch (error) {
      throw Exception('Failed to check message permission: $error');
    }
  }

  /// Dispose resources
  void dispose() {
    _messagesSubscription?.cancel();
  }
}
