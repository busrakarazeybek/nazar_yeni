import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import './supabase_service.dart';

class RealtimeUpdateService {
  static final RealtimeUpdateService _instance = RealtimeUpdateService._internal();
  factory RealtimeUpdateService() => _instance;
  RealtimeUpdateService._internal();

  final SupabaseService _supabaseService = SupabaseService();
  
  // Stream controllers for different update types
  final StreamController<Map<String, dynamic>> _matchUpdatesController = 
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _userStatusUpdatesController = 
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _proposalUpdatesController = 
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _profileUpdatesController = 
      StreamController<Map<String, dynamic>>.broadcast();

  // Subscriptions for real-time channels
  RealtimeChannel? _matchChannel;
  RealtimeChannel? _userStatusChannel;
  RealtimeChannel? _proposalChannel;
  RealtimeChannel? _profileChannel;

  bool _isInitialized = false;
  String? _currentUserId;

  // Public streams
  Stream<Map<String, dynamic>> get matchUpdates => _matchUpdatesController.stream;
  Stream<Map<String, dynamic>> get userStatusUpdates => _userStatusUpdatesController.stream;
  Stream<Map<String, dynamic>> get proposalUpdates => _proposalUpdatesController.stream;
  Stream<Map<String, dynamic>> get profileUpdates => _profileUpdatesController.stream;

  /// Initialize real-time update service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final client = await _supabaseService.client;
      
      // Set up real-time channels
      await _setupRealtimeChannels();
      
      _isInitialized = true;
      print('RealtimeUpdateService initialized successfully');
    } catch (e) {
      print('Error initializing RealtimeUpdateService: $e');
    }
  }

  /// Set current user and subscribe to relevant updates
  Future<void> setCurrentUser(String userId) async {
    if (_currentUserId == userId) return;

    // Unsubscribe from previous user's updates
    if (_currentUserId != null) {
      await _unsubscribeFromUserUpdates();
    }

    _currentUserId = userId;

    // Subscribe to new user's updates
    await _subscribeToUserUpdates();
  }

  /// Clear current user and unsubscribe from updates
  Future<void> clearCurrentUser() async {
    if (_currentUserId != null) {
      await _unsubscribeFromUserUpdates();
      _currentUserId = null;
    }
  }

  /// Setup real-time channels
  Future<void> _setupRealtimeChannels() async {
    final client = await _supabaseService.client;

    // Match updates channel
    _matchChannel = client.channel('match-updates');
    _matchChannel!
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'matches',
          callback: _handleMatchUpdate,
        )
        .subscribe();

    // User status updates channel
    _userStatusChannel = client.channel('user-status-updates');
    _userStatusChannel!
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'user_profiles',
          callback: _handleUserStatusUpdate,
        )
        .subscribe();

    // Match proposal updates channel
    _proposalChannel = client.channel('proposal-updates');
    _proposalChannel!
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'match_proposals',
          callback: _handleProposalUpdate,
        )
        .subscribe();

    // Profile updates channel
    _profileChannel = client.channel('profile-updates');
    _profileChannel!
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'user_profiles',
          callback: _handleProfileUpdate,
        )
        .subscribe();

    print('Real-time channels set up successfully');
  }

  /// Subscribe to current user's specific updates
  Future<void> _subscribeToUserUpdates() async {
    if (_currentUserId == null) return;

    try {
      // Update user's last seen and online status
      await _updateUserOnlineStatus(true);
      
      print('Subscribed to updates for user: $_currentUserId');
    } catch (e) {
      print('Error subscribing to user updates: $e');
    }
  }

  /// Unsubscribe from user updates
  Future<void> _unsubscribeFromUserUpdates() async {
    if (_currentUserId == null) return;

    try {
      // Update user's offline status
      await _updateUserOnlineStatus(false);
      
      print('Unsubscribed from updates for user: $_currentUserId');
    } catch (e) {
      print('Error unsubscribing from user updates: $e');
    }
  }

  /// Handle match updates
  void _handleMatchUpdate(PostgresChangePayload payload) {
    try {
      final eventType = payload.eventType;
      final newRecord = payload.newRecord;
      final oldRecord = payload.oldRecord;

      if (_currentUserId == null) return;

      // Check if current user is involved in this match
      final isUserInvolved = _isUserInvolvedInMatch(newRecord ?? oldRecord);
      if (!isUserInvolved) return;

      final updateData = {
        'type': 'match_update',
        'event': eventType.toString(),
        'match_data': newRecord ?? oldRecord,
        'old_data': oldRecord,
        'timestamp': DateTime.now().toIso8601String(),
      };

      _matchUpdatesController.add(updateData);

      // Handle specific match events
      if (eventType == PostgresChangeEvent.update && newRecord != null) {
        _handleSpecificMatchUpdate(newRecord, oldRecord);
      }

    } catch (e) {
      print('Error handling match update: $e');
    }
  }

  /// Handle specific match update events
  void _handleSpecificMatchUpdate(Map<String, dynamic> newData, Map<String, dynamic>? oldData) {
    try {
      final newStatus = newData['status'] as String?;
      final newTargetStatus = newData['target_status'] as String?;
      final oldStatus = oldData?['status'] as String?;
      final oldTargetStatus = oldData?['target_status'] as String?;

      // Check if match became successful (both accepted)
      if (newStatus == 'accepted' && newTargetStatus == 'accepted' &&
          (oldStatus != 'accepted' || oldTargetStatus != 'accepted')) {
        
        final celebrationData = {
          'type': 'match_success',
          'match_id': newData['id'],
          'message': 'Tebrikler! Yeni bir eşleşmeniz var! 🎉',
          'timestamp': DateTime.now().toIso8601String(),
        };
        
        _matchUpdatesController.add(celebrationData);
      }

      // Check if match was rejected
      if ((newStatus == 'rejected' && oldStatus != 'rejected') ||
          (newTargetStatus == 'rejected' && oldTargetStatus != 'rejected')) {
        
        final rejectionData = {
          'type': 'match_rejected',
          'match_id': newData['id'],
          'message': 'Bir eşleşme teklifi reddedildi.',
          'timestamp': DateTime.now().toIso8601String(),
        };
        
        _matchUpdatesController.add(rejectionData);
      }

    } catch (e) {
      print('Error handling specific match update: $e');
    }
  }

  /// Handle user status updates
  void _handleUserStatusUpdate(PostgresChangePayload payload) {
    try {
      final eventType = payload.eventType;
      final newRecord = payload.newRecord;
      final oldRecord = payload.oldRecord;

      if (newRecord == null) return;

      final updateData = {
        'type': 'user_status_update',
        'event': eventType.toString(),
        'user_data': newRecord,
        'old_data': oldRecord,
        'timestamp': DateTime.now().toIso8601String(),
      };

      _userStatusUpdatesController.add(updateData);

    } catch (e) {
      print('Error handling user status update: $e');
    }
  }

  /// Handle match proposal updates
  void _handleProposalUpdate(PostgresChangePayload payload) {
    try {
      final eventType = payload.eventType;
      final newRecord = payload.newRecord;
      final oldRecord = payload.oldRecord;

      if (_currentUserId == null) return;

      // Check if current user is involved in this proposal
      final isUserInvolved = _isUserInvolvedInProposal(newRecord ?? oldRecord);
      if (!isUserInvolved) return;

      final updateData = {
        'type': 'proposal_update',
        'event': eventType.toString(),
        'proposal_data': newRecord ?? oldRecord,
        'old_data': oldRecord,
        'timestamp': DateTime.now().toIso8601String(),
      };

      _proposalUpdatesController.add(updateData);

      // Handle new proposal creation
      if (eventType == PostgresChangeEvent.insert && newRecord != null) {
        _handleNewProposal(newRecord);
      }

    } catch (e) {
      print('Error handling proposal update: $e');
    }
  }

  /// Handle new proposal creation
  void _handleNewProposal(Map<String, dynamic> proposalData) {
    try {
      final candidateId = proposalData['candidate_id'] as String?;
      final targetCandidateId = proposalData['target_candidate_id'] as String?;

      // Only notify if current user is one of the candidates
      if (_currentUserId == candidateId || _currentUserId == targetCandidateId) {
        final notificationData = {
          'type': 'new_proposal',
          'proposal_id': proposalData['id'],
          'message': 'Yeni bir eşleşme teklifiniz var! 💕',
          'timestamp': DateTime.now().toIso8601String(),
        };
        
        _proposalUpdatesController.add(notificationData);
      }

    } catch (e) {
      print('Error handling new proposal: $e');
    }
  }

  /// Handle profile updates
  void _handleProfileUpdate(PostgresChangePayload payload) {
    try {
      final eventType = payload.eventType;
      final newRecord = payload.newRecord;
      final oldRecord = payload.oldRecord;

      if (newRecord == null) return;

      final updateData = {
        'type': 'profile_update',
        'event': eventType.toString(),
        'profile_data': newRecord,
        'old_data': oldRecord,
        'timestamp': DateTime.now().toIso8601String(),
      };

      _profileUpdatesController.add(updateData);

    } catch (e) {
      print('Error handling profile update: $e');
    }
  }

  /// Check if current user is involved in a match
  bool _isUserInvolvedInMatch(Map<String, dynamic>? matchData) {
    if (matchData == null || _currentUserId == null) return false;

    final candidateId = matchData['candidate_id'] as String?;
    final targetCandidateId = matchData['target_candidate_id'] as String?;
    final selectorId = matchData['selector_id'] as String?;

    return _currentUserId == candidateId || 
           _currentUserId == targetCandidateId || 
           _currentUserId == selectorId;
  }

  /// Check if current user is involved in a proposal
  bool _isUserInvolvedInProposal(Map<String, dynamic>? proposalData) {
    if (proposalData == null || _currentUserId == null) return false;

    final candidateId = proposalData['candidate_id'] as String?;
    final targetCandidateId = proposalData['target_candidate_id'] as String?;
    final selectorId = proposalData['selector_id'] as String?;

    return _currentUserId == candidateId || 
           _currentUserId == targetCandidateId || 
           _currentUserId == selectorId;
  }

  /// Update user's online status
  Future<void> _updateUserOnlineStatus(bool isOnline) async {
    if (_currentUserId == null) return;

    try {
      final client = await _supabaseService.client;
      
      await client
          .from('user_profiles')
          .update({
            'is_online': isOnline,
            'last_seen': DateTime.now().toIso8601String(),
          })
          .eq('id', _currentUserId!);

    } catch (e) {
      print('Error updating user online status: $e');
    }
  }

  /// Get online users count
  Future<int> getOnlineUsersCount() async {
    try {
      final client = await _supabaseService.client;
      
      final response = await client
          .from('user_profiles')
          .select('id')
          .eq('is_online', true);

      return response.length;
    } catch (e) {
      print('Error getting online users count: $e');
      return 0;
    }
  }

  /// Get user's real-time status
  Future<Map<String, dynamic>?> getUserStatus(String userId) async {
    try {
      final client = await _supabaseService.client;
      
      final response = await client
          .from('user_profiles')
          .select('is_online, last_seen')
          .eq('id', userId)
          .single();

      return response;
    } catch (e) {
      print('Error getting user status: $e');
      return null;
    }
  }

  /// Send custom real-time event
  Future<void> sendCustomEvent({
    required String eventType,
    required Map<String, dynamic> payload,
    String? targetUserId,
  }) async {
    try {
      final client = await _supabaseService.client;
      
      // You can implement custom events using Supabase functions
      // or by inserting into a custom events table
      
      await client.from('realtime_events').insert({
        'event_type': eventType,
        'payload': payload,
        'sender_id': _currentUserId,
        'target_user_id': targetUserId,
        'created_at': DateTime.now().toIso8601String(),
      });

    } catch (e) {
      print('Error sending custom event: $e');
    }
  }

  /// Broadcast typing status in chat
  Future<void> broadcastTypingStatus({
    required String conversationId,
    required bool isTyping,
  }) async {
    if (_currentUserId == null) return;

    try {
      final client = await _supabaseService.client;
      
      // Create or update typing status
      await client
          .from('typing_status')
          .upsert({
            'conversation_id': conversationId,
            'user_id': _currentUserId!,
            'is_typing': isTyping,
            'updated_at': DateTime.now().toIso8601String(),
          });

    } catch (e) {
      print('Error broadcasting typing status: $e');
    }
  }

  /// Listen to typing status in conversation
  Stream<List<Map<String, dynamic>>> listenToTypingStatus(String conversationId) {
    final client = _supabaseService.syncClient;
    
    return client
        .from('typing_status')
        .stream(primaryKey: ['user_id', 'conversation_id'])
        .eq('conversation_id', conversationId)
        .map((data) => List<Map<String, dynamic>>.from(data))
        .map((data) => data.where((item) => item['user_id'] != _currentUserId).toList());
  }

  /// Get current user ID
  String? get currentUserId => _currentUserId;

  /// Check if service is initialized
  bool get isInitialized => _isInitialized;

  /// Dispose all resources
  void dispose() {
    // Unsubscribe from channels
    _matchChannel?.unsubscribe();
    _userStatusChannel?.unsubscribe();
    _proposalChannel?.unsubscribe();
    _profileChannel?.unsubscribe();

    // Close stream controllers
    _matchUpdatesController.close();
    _userStatusUpdatesController.close();
    _proposalUpdatesController.close();
    _profileUpdatesController.close();

    _isInitialized = false;
    print('RealtimeUpdateService disposed');
  }
}