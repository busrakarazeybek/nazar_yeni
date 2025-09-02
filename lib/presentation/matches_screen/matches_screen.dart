import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/chat_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _conversations = [];
  String? _errorMessage;
  final ChatService _chatService = ChatService();

  Set<String> _viewedConversations = {}; // Track locally viewed conversations
  Map<String, int> _previousUnreadCounts = {}; // Track previous unread counts

  @override
  void initState() {
    super.initState();
    _loadViewedConversations();
    _loadMatches();
    _clearMessageBadgeInOtherScreens();
  }

  Future<void> _loadViewedConversations() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.currentUserProfile;
      
      if (currentUser != null) {
        final prefs = await SharedPreferences.getInstance();
        final viewedList = prefs.getStringList('viewedConversations_${currentUser.id}') ?? [];
        _viewedConversations = viewedList.toSet();
        print('🔥 MATCHES: Loaded ${_viewedConversations.length} viewed conversations from SharedPreferences');
      }
    } catch (e) {
      print('🔥 MATCHES: Error loading viewed conversations: $e');
    }
  }

  Future<void> _saveViewedConversations() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.currentUserProfile;
      
      if (currentUser != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList('viewedConversations_${currentUser.id}', _viewedConversations.toList());
        print('🔥 MATCHES: Saved ${_viewedConversations.length} viewed conversations to SharedPreferences');
      }
    } catch (e) {
      print('🔥 MATCHES: Error saving viewed conversations: $e');
    }
  }


  void _updateViewedConversationsForNewMessages(List<Map<String, dynamic>> conversations) {
    final conversationsWithNewMessages = <String>{};
    final conversationsWithNoMessages = <String>{};
    
    for (final conversation in conversations) {
      final conversationId = conversation['conversation_id'] as String;
      final unreadCount = conversation['unread_count'] as int;
      final previousUnreadCount = _previousUnreadCounts[conversationId] ?? 0;
      
      // Check if this is genuinely a new message (unread count increased)
      if (unreadCount > previousUnreadCount) {
        // New messages arrived, remove from viewed list
        if (_viewedConversations.contains(conversationId)) {
          conversationsWithNewMessages.add(conversationId);
          print('🔥 MATCHES: New message detected for $conversationId (was $previousUnreadCount, now $unreadCount)');
        }
      } else if (unreadCount == 0) {
        // If conversation has no unread messages and is not in viewed list, add it
        if (!_viewedConversations.contains(conversationId)) {
          conversationsWithNoMessages.add(conversationId);
        }
      }
      
      // Update previous unread count
      _previousUnreadCounts[conversationId] = unreadCount;
    }
    
    bool shouldSave = false;
    
    if (conversationsWithNewMessages.isNotEmpty) {
      _viewedConversations.removeAll(conversationsWithNewMessages);
      shouldSave = true;
      print('🔥 MATCHES: Removed viewed status from ${conversationsWithNewMessages.length} conversations with new messages');
    }
    
    if (conversationsWithNoMessages.isNotEmpty) {
      _viewedConversations.addAll(conversationsWithNoMessages);
      shouldSave = true;
      print('🔥 MATCHES: Added viewed status to ${conversationsWithNoMessages.length} conversations with no unread messages');
    }
    
    if (shouldSave) {
      _saveViewedConversations();
    }
  }

  Future<void> _clearMessageBadgeInOtherScreens() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.currentUserProfile;
      
      if (currentUser != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('hasViewedMessages_${currentUser.id}', true);
        
        // Also clear the unread message count for persistent badge clearing
        final chatService = ChatService();
        final currentUnreadCount = await chatService.getUnreadMessageCount(currentUser.id);
        await prefs.setInt('lastSeenMessageCount_${currentUser.id}', currentUnreadCount);
      }
    } catch (e) {
      print('Error clearing message badge: $e');
    }
  }

  Future<void> _loadMatches() async {
    try {
      print('🔥 MATCHES: _loadMatches called, current conversations count: ${_conversations.length}');
      if (mounted) {
        setState(() {
          _isLoading = true;
          _errorMessage = null;
        });
      }

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.currentUserProfile;

      if (currentUser == null) {
        if (mounted) {
          setState(() {
            _errorMessage = 'Kullanıcı oturumu bulunamadı';
          });
        }
        return;
      }

      print('🔥 MATCHES: Fetching conversations from ChatService...');
      final conversations = await _chatService.getConversations(currentUser.id);
      print('🔥 MATCHES: Received ${conversations.length} conversations');
      
      for (int i = 0; i < conversations.length; i++) {
        final conv = conversations[i];
        print('🔥 MATCHES: Conversation $i - partner: ${conv['partner_name']}, unread_count: ${conv['unread_count']}');
      }

      // Check for new messages and remove viewed status if there are new unread messages
      _updateViewedConversationsForNewMessages(conversations);
      
      if (mounted) {
        setState(() {
          _conversations = conversations;
        });
        print('🔥 MATCHES: setState completed with new conversations');
      }
    } catch (e) {
      print('🔥 MATCHES: Error in _loadMatches: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Konuşmalar yüklenirken hata oluştu: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
        elevation: 0,
        title: Text(
          'Mesajlar',
          style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _loadMatches,
            icon: CustomIconWidget(
              iconName: 'refresh',
              color: AppTheme.lightTheme.primaryColor,
              size: 24,
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadMatches,
        child: _buildBody(),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return _buildLoadingScreen();
    if (_errorMessage != null) return _buildErrorScreen();

    if (_conversations.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(6.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomIconWidget(
                iconName: 'chat',
                color: AppTheme.lightTheme.primaryColor,
                size: 48,
              ),
              SizedBox(height: 2.h),
              Text(
                'Henüz mesaj yok',
                style: AppTheme.lightTheme.textTheme.titleMedium,
              ),
              SizedBox(height: 1.h),
              Text(
                'Eşleşen kişilerle mesajlaşma başladığında burada görünecek.',
                style: TextStyle(color: Colors.grey[600], fontSize: 12.sp),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFF8F9FA),
            Color(0xFFFFFFFF),
          ],
        ),
      ),
      child: ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.h),
        itemCount: _conversations.length,
        itemBuilder: (context, index) {
          final conversation = _conversations[index];
          final latestMessage = conversation['latest_message'];
          final databaseUnreadCount = conversation['unread_count'] as int;
          final conversationId = conversation['conversation_id'] as String;
          final partnerName = conversation['partner_name'] as String;
          final partnerImageUrl = conversation['partner_image_url'] as String?;

          // Use local state to determine if conversation should show badge
          final isViewedLocally = _viewedConversations.contains(conversationId);

          return _buildConversationTile(
            conversation: conversation,
            conversationId: conversationId,
            partnerName: partnerName,
            partnerImageUrl: partnerImageUrl,
            latestMessage: latestMessage,
            unreadCount: databaseUnreadCount,
            isViewedLocally: isViewedLocally,
          );
        },
      ),
    );
  }

  Widget _buildConversationTile({
    required Map<String, dynamic> conversation,
    required String conversationId,
    required String partnerName,
    String? partnerImageUrl,
    Map<String, dynamic>? latestMessage,
    required int unreadCount,
    required bool isViewedLocally,
  }) {
    final currentUser =
        Provider.of<AuthProvider>(context, listen: false).currentUserProfile;
    final isMyMessage =
        latestMessage != null && latestMessage['sender_id'] == currentUser?.id;

    return Container(
      margin: EdgeInsets.symmetric(vertical: 0.5.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(
          horizontal: 4.w,
          vertical: 1.h,
        ),
        leading: Stack(
          children: [
            Container(
              width: 14.w,
              height: 14.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF6C63FF).withOpacity(0.8),
                    Color(0xFF9C27B0).withOpacity(0.8),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF6C63FF).withOpacity(0.3),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: ClipOval(
                child: partnerImageUrl != null && partnerImageUrl.isNotEmpty
                    ? CustomImageWidget(
                        imageUrl: partnerImageUrl,
                        width: 14.w,
                        height: 14.w,
                        fit: BoxFit.cover,
                      )
                    : Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 7.w,
                      ),
              ),
            ),
            // Online indicator (green dot)
            if (unreadCount > 0)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 4.w,
                  height: 4.w,
                  decoration: BoxDecoration(
                    color: Color(0xFF00E676),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFF00E676).withOpacity(0.5),
                        blurRadius: 4,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          partnerName,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16.sp,
            color: Colors.grey[800],
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: latestMessage != null
            ? Padding(
                padding: EdgeInsets.only(top: 0.5.h),
                child: Row(
                  children: [
                    if (isMyMessage) ...[
                      Icon(
                        latestMessage['is_read'] == true
                            ? Icons.done_all
                            : Icons.done,
                        size: 16,
                        color: latestMessage['is_read'] == true
                            ? Colors.blue[600]
                            : Colors.grey[500],
                      ),
                      SizedBox(width: 1.w),
                    ],
                    Expanded(
                      child: Text(
                        latestMessage['content'] as String,
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: (unreadCount > 0 && !isViewedLocally)
                              ? Colors.grey[800]
                              : Colors.grey[600],
                          fontWeight: (unreadCount > 0 && !isViewedLocally)
                              ? FontWeight.w500
                              : FontWeight.normal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              )
            : Padding(
                padding: EdgeInsets.only(top: 0.5.h),
                child: Text(
                  'Henüz mesaj yok',
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: Colors.grey[500],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (latestMessage != null)
              Text(
                _formatMessageTime(DateTime.parse(latestMessage['created_at'])),
                style: TextStyle(
                  fontSize: 11.sp,
                  color: (unreadCount > 0 && !isViewedLocally) 
                      ? Color(0xFF6C63FF) 
                      : Colors.grey[500],
                  fontWeight: (unreadCount > 0 && !isViewedLocally) 
                      ? FontWeight.w600 
                      : FontWeight.normal,
                ),
              ),
            // Only show badge if there are unread messages AND conversation hasn't been viewed locally
            if (unreadCount > 0 && !isViewedLocally) ...[
              SizedBox(height: 0.5.h),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 2.w,
                  vertical: 0.5.h,
                ),
                decoration: BoxDecoration(
                  color: Color(0xFF6C63FF),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF6C63FF).withOpacity(0.3),
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: Text(
                  unreadCount > 99 ? '99+' : unreadCount.toString(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
        onTap: () async {
          print('🔥 MATCHES: Conversation tapped: $conversationId');
          
          // Immediately mark conversation as viewed locally and update UI
          if (mounted) {
            setState(() {
              _viewedConversations.add(conversationId);
            });
          }
          
          // Save to SharedPreferences for persistence
          await _saveViewedConversations();
          print('🔥 MATCHES: Conversation marked as viewed locally and saved');
          
          // Mark messages as read in database (async, don't wait)
          final currentUser = Provider.of<AuthProvider>(context, listen: false).currentUserProfile;
          if (currentUser != null) {
            _chatService.markMessagesAsRead(conversationId, currentUser.id).catchError((e) {
              print('🔥 MATCHES: Error marking messages as read in database: $e');
            });
          }

          // Navigate to chat
          final result = await Navigator.pushNamed(
            context,
            AppRoutes.improvedChatScreen,
            arguments: {
              'matchId': conversation['match_id'],
              'partnerName': partnerName,
              'partnerImageUrl': partnerImageUrl,
              'partnerId': conversation['partner_id'],
            },
          );
          
          // Wait much longer for database to properly update, then reload conversations
          await Future.delayed(Duration(milliseconds: 5000));
          await _loadMatches();
        },
      ),
    );
  }

  String _formatMessageTime(DateTime messageTime) {
    final now = DateTime.now();
    final difference = now.difference(messageTime);

    if (difference.inDays > 7) {
      // More than a week ago, show date
      return '${messageTime.day}/${messageTime.month}/${messageTime.year}';
    } else if (difference.inDays > 0) {
      // Days ago
      if (difference.inDays == 1) {
        return 'Dün';
      } else {
        return '${difference.inDays} gün önce';
      }
    } else if (difference.inHours > 0) {
      // Hours ago
      return '${difference.inHours} saat önce';
    } else if (difference.inMinutes > 0) {
      // Minutes ago
      return '${difference.inMinutes} dk önce';
    } else {
      // Just now
      return 'Şimdi';
    }
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppTheme.lightTheme.primaryColor),
          SizedBox(height: 2.h),
          Text(
            'Konuşmalar yükleniyor...',
            style: AppTheme.lightTheme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(6.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: 'error_outline',
              color: AppTheme.errorColor,
              size: 64,
            ),
            SizedBox(height: 3.h),
            Text(
              'Hata',
              style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                color: AppTheme.errorColor,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              _errorMessage ?? 'Bilinmeyen hata',
              style: AppTheme.lightTheme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4.h),
            ElevatedButton.icon(
              onPressed: _loadMatches,
              icon: CustomIconWidget(
                iconName: 'refresh',
                color: Colors.white,
                size: 20,
              ),
              label: Text('Tekrar Dene'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: 1, // Matches tab active
      onTap: (index) {
        switch (index) {
          case 0:
            Navigator.pushReplacementNamed(
                context, AppRoutes.candidateHomeScreen);
            break;
          case 1:
            // Already on matches screen
            break;
          case 2:
            Navigator.pushReplacementNamed(context, '/my-selectors-screen');
            break;
          case 3:
            Navigator.pushReplacementNamed(context, '/profile-screen');
            break;
        }
      },
      type: BottomNavigationBarType.fixed,
      backgroundColor: AppTheme.lightTheme.colorScheme.surface,
      selectedItemColor: AppTheme.lightTheme.colorScheme.primary,
      unselectedItemColor: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
      elevation: 8,
      items: [
        BottomNavigationBarItem(
          icon: CustomIconWidget(
            iconName: 'home',
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            size: 24,
          ),
          label: 'Ana Sayfa',
        ),
        BottomNavigationBarItem(
          icon: CustomIconWidget(
            iconName: 'favorite',
            color: AppTheme.lightTheme.colorScheme.primary,
            size: 24,
          ),
          label: 'Eşleşmeler',
        ),
        BottomNavigationBarItem(
          icon: CustomIconWidget(
            iconName: 'people',
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            size: 24,
          ),
          label: 'Seçicilerim',
        ),
        BottomNavigationBarItem(
          icon: CustomIconWidget(
            iconName: 'person',
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            size: 24,
          ),
          label: 'Profil',
        ),
      ],
    );
  }
}
