import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import './supabase_service.dart';

class SupabaseNotificationService {
  static final SupabaseNotificationService _instance = SupabaseNotificationService._internal();
  factory SupabaseNotificationService() => _instance;
  SupabaseNotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final SupabaseService _supabaseService = SupabaseService();

  bool _isInitialized = false;
  String? _currentUserId;
  StreamSubscription<List<Map<String, dynamic>>>? _notificationSubscription;
  StreamSubscription<List<Map<String, dynamic>>>? _messageSubscription;
  StreamSubscription<List<Map<String, dynamic>>>? _matchSubscription;

  // Notification types
  static const String typeNewMessage = 'new_message';
  static const String typeMatchProposal = 'match_proposal';
  static const String typeMatchAccepted = 'match_accepted';
  static const String typeNewSelector = 'new_selector';

  /// Initialize notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Request notification permissions
      await _requestPermissions();

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Get current user
      final client = await _supabaseService.client;
      _currentUserId = client.auth.currentUser?.id;

      if (_currentUserId != null) {
        // Subscribe to real-time notifications
        await _subscribeToNotifications();
      }

      _isInitialized = true;
      print('SupabaseNotificationService initialized successfully');
    } catch (e) {
      print('Error initializing SupabaseNotificationService: $e');
    }
  }

  /// Request notification permissions
  Future<void> _requestPermissions() async {
    // Request system notification permission (Android 13+)
    if (await Permission.notification.isDenied) {
      final status = await Permission.notification.request();
      if (status.isDenied) {
        print('User denied notification permissions');
        return;
      }
    }

    print('Notification permissions granted');
  }

  /// Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channels for Android
    await _createNotificationChannels();
  }

  /// Create notification channels for Android
  Future<void> _createNotificationChannels() async {
    const messageChannel = AndroidNotificationChannel(
      'messages',
      'Mesajlar',
      description: 'Yeni mesaj bildirimleri',
      importance: Importance.high,
      sound: RawResourceAndroidNotificationSound('notification'),
    );

    const matchChannel = AndroidNotificationChannel(
      'matches',
      'Eşleşmeler',
      description: 'Eşleşme bildirimleri',
      importance: Importance.high,
      sound: RawResourceAndroidNotificationSound('notification'),
    );

    const generalChannel = AndroidNotificationChannel(
      'general',
      'Genel',
      description: 'Genel bildirimler',
      importance: Importance.defaultImportance,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(messageChannel);

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(matchChannel);

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(generalChannel);
  }

  /// Subscribe to real-time notifications
  Future<void> _subscribeToNotifications() async {
    if (_currentUserId == null) return;

    try {
      final client = await _supabaseService.client;

      // Subscribe to new messages
      _subscribeToMessages();

      // Subscribe to match updates
      _subscribeToMatches();

      print('Subscribed to real-time notifications for user: $_currentUserId');
    } catch (e) {
      print('Error subscribing to notifications: $e');
    }
  }

  /// Subscribe to new messages
  void _subscribeToMessages() {
    if (_currentUserId == null) return;

    final client = _supabaseService.syncClient;
    
    _messageSubscription = client
        .from('messages')
        .stream(primaryKey: ['id'])
        .neq('sender_id', _currentUserId!)
        .listen((List<Map<String, dynamic>> data) {
          if (data.isNotEmpty) {
            final latestMessage = data.last;
            _handleNewMessage(latestMessage);
          }
        });
  }

  /// Subscribe to match updates
  void _subscribeToMatches() {
    if (_currentUserId == null) return;

    final client = _supabaseService.syncClient;
    
    // For now, let's subscribe to all matches and filter in the listener
    _matchSubscription = client
        .from('matches')
        .stream(primaryKey: ['id'])
        .listen((List<Map<String, dynamic>> data) {
          if (data.isNotEmpty) {
            // Filter matches where current user is involved
            final userMatches = data.where((match) =>
              match['candidate_id'] == _currentUserId ||
              match['target_candidate_id'] == _currentUserId ||
              match['selector_id'] == _currentUserId
            ).toList();
            
            if (userMatches.isNotEmpty) {
              final latestMatch = userMatches.last;
              _handleMatchUpdate(latestMatch);
            }
          }
        });
  }

  /// Handle new message
  Future<void> _handleNewMessage(Map<String, dynamic> messageData) async {
    try {
      final client = await _supabaseService.client;
      
      // Get conversation and match info
      final conversationId = messageData['conversation_id'] as String;
      final senderId = messageData['sender_id'] as String;
      final content = messageData['content'] as String;

      // Get conversation details
      final conversation = await client
          .from('conversations')
          .select('match_id')
          .eq('id', conversationId)
          .single();

      final matchId = conversation['match_id'] as String;

      // Get sender details
      final sender = await client
          .from('user_profiles')
          .select('full_name')
          .eq('id', senderId)
          .single();

      final senderName = sender['full_name'] as String;

      // Show notification
      await _showLocalNotification(
        title: senderName,
        body: content,
        channelId: 'messages',
        data: {
          'type': typeNewMessage,
          'match_id': matchId,
          'sender_id': senderId,
          'sender_name': senderName,
        },
      );

    } catch (e) {
      print('Error handling new message notification: $e');
    }
  }

  /// Handle match update
  Future<void> _handleMatchUpdate(Map<String, dynamic> matchData) async {
    try {
      final status = matchData['status'] as String;
      final targetStatus = matchData['target_status'] as String;
      final candidateId = matchData['candidate_id'] as String;
      final targetCandidateId = matchData['target_candidate_id'] as String;
      final selectorId = matchData['selector_id'] as String;

      // Check if both candidates accepted (new match)
      if (status == 'accepted' && targetStatus == 'accepted') {
        await _handleMatchAccepted(matchData);
      }
      // Check if new match proposal for current user
      else if (_currentUserId == candidateId || _currentUserId == targetCandidateId) {
        await _handleNewMatchProposal(matchData);
      }

    } catch (e) {
      print('Error handling match update notification: $e');
    }
  }

  /// Handle match accepted notification
  Future<void> _handleMatchAccepted(Map<String, dynamic> matchData) async {
    await _showLocalNotification(
      title: '🎉 Yeni Eşleşme!',
      body: 'Tebrikler! Yeni bir eşleşmeniz var. Şimdi mesajlaşabilirsiniz.',
      channelId: 'matches',
      data: {
        'type': typeMatchAccepted,
        'match_id': matchData['id'],
      },
    );
  }

  /// Handle new match proposal notification
  Future<void> _handleNewMatchProposal(Map<String, dynamic> matchData) async {
    try {
      final client = await _supabaseService.client;
      
      // Get selector details
      final selectorId = matchData['selector_id'] as String;
      final selector = await client
          .from('user_profiles')
          .select('full_name')
          .eq('id', selectorId)
          .single();

      final selectorName = selector['full_name'] as String;

      await _showLocalNotification(
        title: '💕 Yeni Eşleşme Teklifi',
        body: '$selectorName size bir eşleşme teklifi gönderdi!',
        channelId: 'matches',
        data: {
          'type': typeMatchProposal,
          'match_id': matchData['id'],
          'selector_id': selectorId,
          'selector_name': selectorName,
        },
      );

    } catch (e) {
      print('Error handling match proposal notification: $e');
    }
  }

  /// Show local notification
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    required String channelId,
    Map<String, String>? data,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'general',
      'Genel Bildirimler',
      channelDescription: 'Genel uygulama bildirimleri',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      notificationDetails,
      payload: data != null ? jsonEncode(data) : null,
    );
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    if (response.payload != null) {
      try {
        final data = jsonDecode(response.payload!) as Map<String, dynamic>;
        _handleNotificationTap(data);
      } catch (e) {
        print('Error parsing notification payload: $e');
      }
    }
  }

  /// Handle notification tap navigation
  void _handleNotificationTap(Map<String, dynamic> data) {
    final type = data['type'] as String?;

    switch (type) {
      case typeNewMessage:
        _navigateToChat(data);
        break;
      case typeMatchProposal:
        _navigateToMatchProposal(data);
        break;
      case typeMatchAccepted:
        _navigateToMatches();
        break;
      case typeNewSelector:
        _navigateToSelectors();
        break;
    }
  }

  /// Navigate to chat screen
  void _navigateToChat(Map<String, dynamic> data) {
    // You can implement navigation here using your app's navigation system
    // For example, using a global navigator key or context
    print('Navigate to chat: ${data['match_id']}');
    
    // Example navigation (you'll need to implement this based on your app structure):
    // Navigator.pushNamed(context, AppRoutes.improvedChatScreen, arguments: {
    //   'matchId': data['match_id'],
    //   'partnerName': data['sender_name'],
    //   'partnerId': data['sender_id'],
    // });
  }

  /// Navigate to match proposal screen
  void _navigateToMatchProposal(Map<String, dynamic> data) {
    print('Navigate to match proposal: ${data['match_id']}');
    
    // Example navigation:
    // Navigator.pushNamed(context, AppRoutes.matchProposalNotificationScreen, arguments: {
    //   'proposalId': data['match_id'],
    // });
  }

  /// Navigate to matches screen
  void _navigateToMatches() {
    print('Navigate to matches screen');
    
    // Example navigation:
    // Navigator.pushNamed(context, AppRoutes.matchesScreen);
  }

  /// Navigate to selectors screen
  void _navigateToSelectors() {
    print('Navigate to selectors screen');
    
    // Example navigation:
    // Navigator.pushNamed(context, AppRoutes.mySelectorsScreen);
  }

  /// Create notification for new match proposal
  Future<void> notifyNewMatchProposal({
    required String candidateId,
    required String targetCandidateId,
    required String selectorName,
    required String matchId,
  }) async {
    // This would be called when a new match proposal is created
    print('New match proposal notification created for match: $matchId');
  }

  /// Create notification for new message
  Future<void> notifyNewMessage({
    required String recipientId,
    required String senderName,
    required String message,
    required String matchId,
  }) async {
    // This would be called when a new message is sent
    print('New message notification created for recipient: $recipientId');
  }

  /// Set current user
  void setCurrentUser(String userId) {
    if (_currentUserId != userId) {
      _currentUserId = userId;
      
      // Cancel existing subscriptions
      _messageSubscription?.cancel();
      _matchSubscription?.cancel();
      
      // Subscribe with new user
      _subscribeToNotifications();
    }
  }

  /// Clear current user
  void clearCurrentUser() {
    _currentUserId = null;
    _messageSubscription?.cancel();
    _matchSubscription?.cancel();
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    final status = await Permission.notification.status;
    return status.isGranted;
  }

  /// Get unread notification count
  Future<int> getUnreadNotificationCount() async {
    if (_currentUserId == null) return 0;

    try {
      final client = await _supabaseService.client;

      // Count unread messages
      final unreadMessages = await client
          .from('messages')
          .select('id')
          .neq('sender_id', _currentUserId!)
          .eq('is_read', false);

      return unreadMessages.length;
    } catch (e) {
      print('Error getting unread notification count: $e');
      return 0;
    }
  }

  /// Mark all notifications as read
  Future<void> markAllNotificationsAsRead() async {
    if (_currentUserId == null) return;

    try {
      final client = await _supabaseService.client;

      // Mark all messages as read for current user
      await client
          .from('messages')
          .update({'is_read': true, 'read_at': DateTime.now().toIso8601String()})
          .neq('sender_id', _currentUserId!)
          .eq('is_read', false);

      print('All notifications marked as read');
    } catch (e) {
      print('Error marking notifications as read: $e');
    }
  }

  /// Send candidate request notification
  Future<void> sendCandidateRequestNotification({
    required String candidateId,
    required String selectorName,
    required String relationshipDegree,
  }) async {
    try {
      final client = await SupabaseService().client;
      
      // Create notification record
      await client.from('notifications').insert({
        'user_id': candidateId,
        'type': 'candidate_request',
        'title': 'Yeni Görücü İsteği',
        'message': '$selectorName sizi ($relationshipDegree) görücülük sisteminde adayı olarak eklemek istiyor.',
        'data': {
          'selector_name': selectorName,
          'relationship_degree': relationshipDegree,
          'type': 'candidate_request'
        },
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
      });

      print('Candidate request notification sent to: $candidateId');
    } catch (e) {
      print('Error sending candidate request notification: $e');
      rethrow;
    }
  }

  /// Dispose resources
  void dispose() {
    _notificationSubscription?.cancel();
    _messageSubscription?.cancel();
    _matchSubscription?.cancel();
  }
}