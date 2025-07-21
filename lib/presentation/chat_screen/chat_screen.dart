import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../models/message.dart';
import '../../providers/match_provider.dart';
import './widgets/chat_header_widget.dart';
import './widgets/chat_input_widget.dart';
import './widgets/message_bubble_widget.dart';

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
  bool _isTyping = false;
  late final String? _matchId;
  late final String? _currentUserId;

  // Supabase client
  final SupabaseClient _client = Supabase.instance.client;

  // Mesaj gönder
  Future<void> sendMessage({
    required String matchId,
    required String senderId,
    required String content,
  }) async {
    await _client.from('messages').insert({
      'match_id': matchId,
      'sender_id': senderId,
      'content': content,
      'is_read': false,
    });
  }

  // Mesajları çek (en yeni 50 mesaj)
  Future<List<Message>> fetchMessages(String matchId) async {
    final response = await _client
        .from('messages')
        .select('*, sender:user_profiles!sender_id(*)')
        .eq('match_id', matchId)
        .order('created_at', ascending: true)
        .limit(50);
    return (response as List).map((json) => Message.fromJson(json)).toList();
  }

  // Gerçek zamanlı mesaj stream'i
  Stream<List<Message>> subscribeToMessages(String matchId) {
    final stream = _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('match_id', matchId)
        .order('created_at', ascending: true)
        .limit(50);
    return stream.map((event) =>
        (event as List).map((json) => Message.fromJson(json)).toList());
  }

  // Mock match partner data
  final Map<String, dynamic> _matchPartner = {
    "id": 1,
    "name": "Ayşe Demir",
    "profileImage":
        "https://images.pexels.com/photos/774909/pexels-photo-774909.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1",
    "isOnline": true,
    "lastSeen": DateTime.now().subtract(const Duration(minutes: 2)),
  };

  @override
  void initState() {
    super.initState();
    _matchId = widget.matchId;
    // Kullanıcı id'sini AuthProvider'dan al
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _currentUserId = authProvider.currentUser?.id;
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkMatchStatus());
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

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty ||
        _matchId == null ||
        _currentUserId == null) {
      return;
    }
    final content = _messageController.text.trim();
    _messageController.clear();
    setState(() {
      _isTyping = false;
    });
    await sendMessage(
      matchId: _matchId,
      senderId: _currentUserId,
      content: content,
    );
    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollToBottom();
    });
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
          '${_matchPartner['name']} kullanıcısını engellemek istediğinizden emin misiniz? Bu işlem geri alınamaz.',
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

  void _checkMatchStatus() {
    if (widget.matchId == null) {
      _showNotAllowedAndPop('Eşleşme bulunamadı.');
      return;
    }
    final matchProvider = Provider.of<MatchProvider>(context, listen: false);
    final match = matchProvider.getMatchById(widget.matchId!);
    if (match == null || !match.isMatched) {
      _showNotAllowedAndPop('Sadece eşleşmiş adaylarla mesajlaşabilirsiniz.');
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
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Chat Header
            ChatHeaderWidget(
              matchPartner:
                  _matchPartner, // TODO: partner bilgisini dinamik yap
              onBackPressed: () => Navigator.pop(context),
              onMorePressed: _showUserOptions,
            ),
            // Messages List
            Expanded(
              child: _matchId == null
                  ? Center(child: Text('Eşleşme bulunamadı'))
                  : StreamBuilder<List<Message>>(
                      stream: subscribeToMessages(_matchId),
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
                        return ListView.builder(
                          controller: _scrollController,
                          padding: EdgeInsets.symmetric(
                              horizontal: 4.w, vertical: 1.h),
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final message = messages[index];
                            return MessageBubbleWidget(
                              message: {
                                'isSent': message.senderId == _currentUserId,
                                'isRead': message.isRead,
                                'timestamp': message.createdAt,
                                'message': message.content,
                              },
                              onLongPress: () {},
                            );
                          },
                        );
                      },
                    ),
            ),
            // Typing Indicator
            if (_isTyping)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                child: Row(
                  children: [
                    Container(
                      width: 12.w,
                      height: 12.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.lightTheme.colorScheme.outline
                            .withValues(alpha: 0.3),
                      ),
                      child: Center(
                        child: SizedBox(
                          width: 4.w,
                          height: 4.w,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppTheme.lightTheme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      'yazıyor...',
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            // Chat Input
            ChatInputWidget(
              controller: _messageController,
              focusNode: _messageFocusNode,
              onSend: _sendMessage,
              onTypingChanged: (isTyping) {
                setState(() {
                  _isTyping = isTyping;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
