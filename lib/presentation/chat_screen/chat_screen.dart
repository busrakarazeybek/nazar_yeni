import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'dart:async';

import '../../core/app_export.dart';
import '../../models/message.dart';
import '../../services/chat_service.dart';
import './widgets/chat_header_widget.dart';
import './widgets/chat_input_widget.dart';
import './widgets/modern_message_bubble_widget.dart';

class ChatScreen extends StatefulWidget {
  final String? matchId;
  const ChatScreen({super.key, this.matchId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _messageFocusNode = FocusNode();
  final ChatService _chatService = ChatService();
  
  bool _isTyping = false;
  String? _currentUserId;
  Map<String, dynamic>? _matchPartner;
  String? _matchId;


  @override
  void initState() {
    super.initState();
    _matchId = widget.matchId;
    // Kullanıcı id'sini AuthProvider'dan al
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _currentUserId = authProvider.currentUser?.id;
    
    // Navigation arguments'dan partner bilgisini al
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      _matchPartner = {
        "id": args?['partnerId'] ?? '',
        "name": args?['partnerName'] ?? 'Bilinmeyen Kullanıcı',
        "profileImage": args?['partnerImageUrl'] ?? '',
        "isOnline": true, // TODO: Implement real online status
        "lastSeen": DateTime.now().subtract(const Duration(minutes: 2)),
      };
      setState(() {}); // Refresh UI with partner data
      _checkMatchStatus();
    });
    
    _messageFocusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _messageController.dispose();
    _messageFocusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (_messageFocusNode.hasFocus) {
      Future.delayed(const Duration(milliseconds: 300), () {
        _scrollToBottom();
      });
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  // Send message function
  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    
    if (messageText.isEmpty || _matchId == null || _currentUserId == null) {
      return;
    }

    try {
      // Clear the input immediately for better UX
      _messageController.clear();
      
      // Get or create conversation
      final conversationId = await _chatService.getOrCreateConversation(_matchId!);
      
      // Send message
      await _chatService.sendMessage(
        conversationId: conversationId,
        senderId: _currentUserId!,
        content: messageText,
      );

      // Scroll to bottom after sending
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Mesaj gönderilemedi: $e'),
          backgroundColor: Colors.red,
        ),
      );
      
      // Restore the message text if sending failed
      _messageController.text = messageText;
    }
  }


  void _onMessageLongPress(Map<String, dynamic> message) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.lightTheme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 4.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12.w,
              height: 0.5.h,
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 2.h),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'content_copy',
                color: AppTheme.lightTheme.colorScheme.onSurface,
                size: 24,
              ),
              title: Text(
                'Kopyala',
                style: AppTheme.lightTheme.textTheme.bodyLarge,
              ),
              onTap: () {
                Navigator.pop(context);
                // Copy message functionality
              },
            ),
            if (message['isSent'] == true)
              ListTile(
                leading: CustomIconWidget(
                  iconName: 'delete',
                  color: AppTheme.errorColor,
                  size: 24,
                ),
                title: Text(
                  'Sil',
                  style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                    color: AppTheme.errorColor,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _deleteMessage(message['id']);
                },
              ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'report',
                color: AppTheme.warningColor,
                size: 24,
              ),
              title: Text(
                'Uygunsuz İçerik Bildir',
                style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                  color: AppTheme.warningColor,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _reportMessage(message);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _deleteMessage(int messageId) {
    setState(() {
      // This functionality needs to be implemented with Supabase
      // For now, it's a placeholder
    });
  }

  void _reportMessage(Map<String, dynamic> message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.lightTheme.colorScheme.surface,
        title: Text(
          'Mesajı Bildir',
          style: AppTheme.lightTheme.textTheme.titleLarge,
        ),
        content: Text(
          'Bu mesajı uygunsuz içerik olarak bildirmek istediğinizden emin misiniz?',
          style: AppTheme.lightTheme.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'İptal',
              style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurface,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Report message functionality
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.warningColor,
            ),
            child: Text(
              'Bildir',
              style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showUserOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.lightTheme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 4.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12.w,
              height: 0.5.h,
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 2.h),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'block',
                color: AppTheme.errorColor,
                size: 24,
              ),
              title: Text(
                'Kullanıcıyı Engelle',
                style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                  color: AppTheme.errorColor,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _blockUser();
              },
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'report_problem',
                color: AppTheme.warningColor,
                size: 24,
              ),
              title: Text(
                'Konuşmayı Bildir',
                style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                  color: AppTheme.warningColor,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _reportConversation();
              },
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'emergency',
                color: AppTheme.errorColor,
                size: 24,
              ),
              title: Text(
                'Acil Durum İletişim',
                style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                  color: AppTheme.errorColor,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _emergencyContact();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _blockUser() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.lightTheme.colorScheme.surface,
        title: Text(
          'Kullanıcıyı Engelle',
          style: AppTheme.lightTheme.textTheme.titleLarge,
        ),
        content: Text(
          '${_matchPartner?['name'] ?? 'Bu'} kullanıcısını engellemek istediğinizden emin misiniz? Bu işlem geri alınamaz.',
          style: AppTheme.lightTheme.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'İptal',
              style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurface,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
              // Block user functionality
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: Text(
              'Engelle',
              style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _reportConversation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.lightTheme.colorScheme.surface,
        title: Text(
          'Konuşmayı Bildir',
          style: AppTheme.lightTheme.textTheme.titleLarge,
        ),
        content: Text(
          'Bu konuşmayı uygunsuz davranış nedeniyle bildirmek istediğinizden emin misiniz?',
          style: AppTheme.lightTheme.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'İptal',
              style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurface,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Report conversation functionality
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.warningColor,
            ),
            child: Text(
              'Bildir',
              style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _emergencyContact() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.lightTheme.colorScheme.surface,
        title: Text(
          'Acil Durum İletişim',
          style: AppTheme.lightTheme.textTheme.titleLarge,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Acil durumda aşağıdaki numaraları arayabilirsiniz:',
              style: AppTheme.lightTheme.textTheme.bodyMedium,
            ),
            SizedBox(height: 1.h),
            Text(
              '• Polis: 155',
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '• Jandarma: 156',
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '• Alo Şiddet Hattı: 183',
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Tamam',
              style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                color: AppTheme.lightTheme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshMessages() async {
    // Simulate loading message history
    await Future.delayed(const Duration(seconds: 1));
    // Add pagination logic here
  }

  void _checkMatchStatus() async {
    if (widget.matchId == null) {
      _showNotAllowedAndPop('Eşleşme bulunamadı.');
      return;
    }
    
    try {
      final canSend = await _chatService.canSendMessage(widget.matchId!, _currentUserId!);
      
      if (!canSend) {
        _showNotAllowedAndPop('Sadece eşleşmiş adaylarla mesajlaşabilirsiniz.');
      }
    } catch (e) {
      _showNotAllowedAndPop('Eşleşme durumu kontrol edilemedi.');
    }
  }

  void _showNotAllowedAndPop(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
    Future.delayed(const Duration(milliseconds: 800), () {
      Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Show loading while partner data is being loaded
    if (_matchPartner == null) {
      return Scaffold(
        backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Chat Header
            ChatHeaderWidget(
              matchPartner: _matchPartner!,
              onBackPressed: () => Navigator.pop(context),
              onMorePressed: _showUserOptions,
            ),
            // Messages List
            Expanded(
              child: _matchId == null
                  ? Center(child: Text('Eşleşme bulunamadı'))
                  : StreamBuilder<List<Message>>(
                      stream: _chatService.streamMessagesForMatch(_matchId!),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          return Center(child: Text('Mesajlar yüklenemedi'));
                        }
                        final messages = snapshot.data ?? [];
                        if (messages.isEmpty) {
                          return Center(child: Text('Henüz mesaj yok.'));
                        }
                        WidgetsBinding.instance
                            .addPostFrameCallback((_) => _scrollToBottom());
                        return Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Color(0xFFF8F9FA),
                                Color(0xFFE9ECEF).withAlpha(51),
                              ],
                            ),
                          ),
                          child: ListView.builder(
                            controller: _scrollController,
                            padding: EdgeInsets.symmetric(vertical: 2.h),
                            itemCount: messages.length,
                            itemBuilder: (context, index) {
                              final message = messages[index];
                              final isMe = message.senderId == _currentUserId;
                              return ModernMessageBubbleWidget(
                                message: message,
                                isMe: isMe,
                                showAvatar: true,
                                partnerImageUrl: _matchPartner?['profileImage'],
                                currentUserImageUrl: Provider.of<AuthProvider>(context, listen: false).currentUserProfile?.imageUrl,
                                onLongPress: () {},
                              );
                            },
                          ),
                        );
                      },
                    ),
            ),
            // Typing Indicator - Disabled for now since it needs real-time implementation
            // if (_isTyping)
            //   Container(
            //     padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
            //     child: Row(
            //       children: [
            //         Container(
            //           width: 12.w,
            //           height: 12.w,
            //           decoration: BoxDecoration(
            //             shape: BoxShape.circle,
            //             color: AppTheme.lightTheme.colorScheme.outline
            //                 .withValues(alpha: 0.3),
            //           ),
            //           child: Center(
            //             child: SizedBox(
            //               width: 4.w,
            //               height: 4.w,
            //               child: CircularProgressIndicator(
            //                 strokeWidth: 2,
            //                 valueColor: AlwaysStoppedAnimation<Color>(
            //                   AppTheme.lightTheme.colorScheme.primary,
            //                 ),
            //               ),
            //             ),
            //           ),
            //         ),
            //         SizedBox(width: 2.w),
            //         Text(
            //           'yazıyor...',
            //           style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
            //             fontStyle: FontStyle.italic,
            //           ),
            //         ),
            //       ],
            //     ),
            //   ),
            // Chat Input
            ChatInputWidget(
              controller: _messageController,
              focusNode: _messageFocusNode,
              onSend: _sendMessage,
              onTypingChanged: (isTyping) {
                // Disabled typing indicator for now
                // setState(() {
                //   _isTyping = isTyping;
                // });
              },
            ),
          ],
        ),
      ),
    );
  }
}
