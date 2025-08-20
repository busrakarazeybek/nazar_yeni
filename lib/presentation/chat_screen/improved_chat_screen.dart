import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/app_export.dart';
import '../../models/message.dart';
import '../../services/chat_service.dart';
import './widgets/chat_header_widget.dart';
import './widgets/modern_message_bubble_widget.dart';

class ImprovedChatScreen extends StatefulWidget {
  final String matchId;
  final String? partnerName;
  final String? partnerImageUrl;
  final String? partnerId;

  const ImprovedChatScreen({
    super.key,
    required this.matchId,
    this.partnerName,
    this.partnerImageUrl,
    this.partnerId,
  });

  @override
  State<ImprovedChatScreen> createState() => _ImprovedChatScreenState();
}

class _ImprovedChatScreenState extends State<ImprovedChatScreen>
    with WidgetsBindingObserver {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _messageFocusNode = FocusNode();
  final ChatService _chatService = ChatService();

  bool _isLoading = true;
  bool _isSending = false;
  bool _hasError = false;
  String? _errorMessage;
  String? _conversationId;
  String? _currentUserId;
  List<Message> _messages = [];
  StreamSubscription<List<Message>>? _messagesSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeChat();
    _messageFocusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _messagesSubscription?.cancel();
    _scrollController.dispose();
    _messageController.dispose();
    _messageFocusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _conversationId != null) {
      _markMessagesAsRead();
    }
  }

  Future<void> _initializeChat() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      // Get current user
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      _currentUserId = authProvider.currentUserProfile?.id;

      if (_currentUserId == null) {
        throw Exception('Kullanıcı oturumu bulunamadı');
      }

      // Check if user can send messages
      final canSend = await _chatService.canSendMessage(widget.matchId, _currentUserId!);
      if (!canSend) {
        throw Exception('Bu konuşmada mesaj gönderme yetkiniz yok');
      }

      // Get or create conversation
      _conversationId = await _chatService.getOrCreateConversation(widget.matchId);

      // Load initial messages
      _messages = await _chatService.getMessages(_conversationId!);

      // Subscribe to real-time updates
      _subscribeToMessages();

      // Mark messages as read
      _markMessagesAsRead();

      setState(() {
        _isLoading = false;
      });

      // Scroll to bottom
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  void _subscribeToMessages() {
    if (_conversationId == null) return;

    _messagesSubscription?.cancel();
    _messagesSubscription = _chatService
        .streamMessages(_conversationId!)
        .listen(
          (messages) {
            setState(() {
              _messages = messages;
            });
            _markMessagesAsRead();
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _scrollToBottom();
            });
          },
          onError: (error) {
            print('Message stream error: $error');
          },
        );
  }

  Future<void> _markMessagesAsRead() async {
    if (_conversationId == null || _currentUserId == null) return;

    try {
      await _chatService.markMessagesAsRead(_conversationId!, _currentUserId!);
      
      // Also update SharedPreferences to clear persistent message badge
      final prefs = await SharedPreferences.getInstance();
      final currentUnreadCount = await _chatService.getUnreadMessageCount(_currentUserId!);
      await prefs.setInt('lastSeenMessageCount_$_currentUserId', currentUnreadCount);
    } catch (e) {
      print('Error marking messages as read: $e');
    }
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

  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();

    if (messageText.isEmpty || _isSending || _conversationId == null || _currentUserId == null) {
      return;
    }

    try {
      setState(() {
        _isSending = true;
      });

      // Clear input immediately for better UX
      _messageController.clear();

      // Send message
      await _chatService.sendMessage(
        conversationId: _conversationId!,
        senderId: _currentUserId!,
        content: messageText,
      );

      // Scroll to bottom
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    } catch (e) {
      // Restore message text if sending failed
      _messageController.text = messageText;

      // Show error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Mesaj gönderilemedi: $e'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Tekrar Dene',
              onPressed: _sendMessage,
            ),
          ),
        );
      }
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  Future<void> _deleteMessage(Message message) async {
    try {
      await _chatService.deleteMessage(message.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mesaj silindi'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Mesaj silinemedi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showMessageOptions(Message message) {
    if (message.senderId != _currentUserId) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(4.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Mesajı Sil'),
              onTap: () {
                Navigator.pop(context);
                _deleteMessage(message);
              },
            ),
            ListTile(
              leading: const Icon(Icons.cancel),
              title: const Text('İptal'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F9FA),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(8.h),
        child: ChatHeaderWidget(
          matchPartner: {
            'name': widget.partnerName ?? 'Kullanıcı',
            'profileImage': widget.partnerImageUrl ?? '',
            'isOnline': true, // TODO: Implement real online status
            'lastSeen': DateTime.now().subtract(const Duration(minutes: 2)),
          },
          onBackPressed: () => Navigator.of(context).pop(),
          onMorePressed: () {
            // TODO: Show chat options menu
          },
        ),
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: _buildMessagesList(),
          ),
          
          // Message Input
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            SizedBox(height: 2.h),
            Text(
              'Bir hata oluştu',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              _errorMessage ?? 'Bilinmeyen hata',
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 2.h),
            ElevatedButton(
              onPressed: _initializeChat,
              child: const Text('Tekrar Dene'),
            ),
          ],
        ),
      );
    }

    if (_messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            SizedBox(height: 2.h),
            Text(
              'Henüz mesaj yok',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'İlk mesajınızı göndererek konuşmaya başlayın',
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final isMe = message.senderId == _currentUserId;
        final showAvatar = index == _messages.length - 1 ||
            _messages[index + 1].senderId != message.senderId;

        return GestureDetector(
          onLongPress: () => _showMessageOptions(message),
          child: ModernMessageBubbleWidget(
            message: message,
            isMe: isMe,
            showAvatar: showAvatar,
            partnerImageUrl: widget.partnerImageUrl,
            currentUserImageUrl: Provider.of<AuthProvider>(context, listen: false).currentUserProfile?.imageUrl,
          ),
        );
      },
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Colors.grey[300]!,
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Text Input
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(25),
                ),
                child: TextField(
                  controller: _messageController,
                  focusNode: _messageFocusNode,
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                  decoration: InputDecoration(
                    hintText: 'Mesajınızı yazın...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 4.w,
                      vertical: 2.h,
                    ),
                  ),
                ),
              ),
            ),
            
            SizedBox(width: 2.w),
            
            // Send Button
            Container(
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.primaryColor,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: _isSending ? null : _sendMessage,
                icon: _isSending
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.send,
                        color: Colors.white,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}