import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/chat_service.dart';

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

  @override
  void initState() {
    super.initState();
    _loadMatches();
  }

  Future<void> _loadMatches() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.currentUserProfile;

      if (currentUser == null) {
        setState(() {
          _errorMessage = 'Kullanıcı oturumu bulunamadı';
        });
        return;
      }

      final conversations = await _chatService.getConversations(currentUser.id);

      setState(() {
        _conversations = conversations;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Konuşmalar yüklenirken hata oluştu: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
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
          final unreadCount = conversation['unread_count'] as int;
          final partnerName = conversation['partner_name'] as String;
          final partnerImageUrl = conversation['partner_image_url'] as String?;

          return _buildConversationTile(
            conversation: conversation,
            partnerName: partnerName,
            partnerImageUrl: partnerImageUrl,
            latestMessage: latestMessage,
            unreadCount: unreadCount,
          );
        },
      ),
    );
  }

  Widget _buildConversationTile({
    required Map<String, dynamic> conversation,
    required String partnerName,
    String? partnerImageUrl,
    Map<String, dynamic>? latestMessage,
    required int unreadCount,
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
                          color: unreadCount > 0
                              ? Colors.grey[800]
                              : Colors.grey[600],
                          fontWeight: unreadCount > 0
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
                  color: unreadCount > 0 ? Color(0xFF6C63FF) : Colors.grey[500],
                  fontWeight:
                      unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            if (unreadCount > 0) ...[
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
          // Mark messages as read when entering chat
          final currentUser = Provider.of<AuthProvider>(context, listen: false)
              .currentUserProfile;
          if (currentUser != null && conversation['conversation_id'] != null) {
            try {
              await _chatService.markMessagesAsRead(
                conversation['conversation_id'],
                currentUser.id,
              );

              // Immediately update the UI to remove the notification badge
              setState(() {
                // Find and update the conversation in the list
                final conversationIndex = _conversations.indexWhere(
                  (conv) => conv['conversation_id'] == conversation['conversation_id']
                );
                if (conversationIndex != -1) {
                  _conversations[conversationIndex]['unread_count'] = 0;
                }
              });
            } catch (e) {
              print('Error marking messages as read: $e');
            }
          }

          Navigator.pushNamed(
            context,
            AppRoutes.improvedChatScreen,
            arguments: {
              'matchId': conversation['match_id'],
              'partnerName': partnerName,
              'partnerImageUrl': partnerImageUrl,
              'partnerId': conversation['partner_id'],
            },
          );
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
          label: 'Mesajlar',
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
