import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'dart:async';

import '../../core/app_export.dart';
import '../../services/realtime_update_service.dart';

class RealtimeUpdatesWidget extends StatefulWidget {
  final Widget child;

  const RealtimeUpdatesWidget({
    super.key,
    required this.child,
  });

  @override
  State<RealtimeUpdatesWidget> createState() => _RealtimeUpdatesWidgetState();
}

class _RealtimeUpdatesWidgetState extends State<RealtimeUpdatesWidget>
    with TickerProviderStateMixin {
  late RealtimeUpdateService _realtimeService;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  StreamSubscription<Map<String, dynamic>>? _matchUpdatesSubscription;
  StreamSubscription<Map<String, dynamic>>? _proposalUpdatesSubscription;

  List<Map<String, dynamic>> _recentUpdates = [];
  Timer? _updateDisplayTimer;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _initializeRealtimeService();
  }

  void _initializeRealtimeService() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _realtimeService = authProvider.realtimeService;

    // Subscribe to match updates
    _matchUpdatesSubscription = _realtimeService.matchUpdates.listen(
      _handleMatchUpdate,
    );

    // Subscribe to proposal updates
    _proposalUpdatesSubscription = _realtimeService.proposalUpdates.listen(
      _handleProposalUpdate,
    );
  }

  void _handleMatchUpdate(Map<String, dynamic> update) {
    final updateType = update['type'] as String?;
    
    if (updateType == 'match_success') {
      _showUpdate(
        title: 'Yeni Eşleşme! 🎉',
        message: update['message'] as String,
        color: Colors.green,
        icon: Icons.favorite,
        duration: const Duration(seconds: 5),
      );
    } else if (updateType == 'match_rejected') {
      _showUpdate(
        title: 'Eşleşme Durumu',
        message: update['message'] as String,
        color: Colors.orange,
        icon: Icons.info,
        duration: const Duration(seconds: 3),
      );
    } else if (updateType == 'match_update') {
      final matchData = update['match_data'] as Map<String, dynamic>?;
      final event = update['event'] as String?;
      
      if (event == 'UPDATE' && matchData != null) {
        _showUpdate(
          title: 'Eşleşme Güncellendi',
          message: 'Bir eşleşmenizde değişiklik oldu',
          color: Colors.blue,
          icon: Icons.update,
          duration: const Duration(seconds: 3),
        );
      }
    }
  }

  void _handleProposalUpdate(Map<String, dynamic> update) {
    final updateType = update['type'] as String?;
    
    if (updateType == 'new_proposal') {
      _showUpdate(
        title: 'Yeni Teklif! 💕',
        message: update['message'] as String,
        color: Colors.pink,
        icon: Icons.favorite_border,
        duration: const Duration(seconds: 4),
      );
    } else if (updateType == 'proposal_update') {
      final event = update['event'] as String?;
      
      if (event == 'UPDATE') {
        _showUpdate(
          title: 'Teklif Güncellendi',
          message: 'Bir teklifinizde değişiklik oldu',
          color: Colors.purple,
          icon: Icons.edit,
          duration: const Duration(seconds: 3),
        );
      }
    }
  }

  void _showUpdate({
    required String title,
    required String message,
    required Color color,
    required IconData icon,
    Duration duration = const Duration(seconds: 3),
  }) {
    final update = {
      'title': title,
      'message': message,
      'color': color,
      'icon': icon,
      'timestamp': DateTime.now(),
    };

    setState(() {
      _recentUpdates.insert(0, update);
      if (_recentUpdates.length > 3) {
        _recentUpdates.removeLast();
      }
    });

    _animationController.forward();

    // Auto hide after duration
    _updateDisplayTimer?.cancel();
    _updateDisplayTimer = Timer(duration, () {
      if (mounted) {
        _animationController.reverse().then((_) {
          if (mounted) {
            setState(() {
              _recentUpdates.clear();
            });
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _matchUpdatesSubscription?.cancel();
    _proposalUpdatesSubscription?.cancel();
    _updateDisplayTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_recentUpdates.isNotEmpty) _buildUpdateOverlay(),
      ],
    );
  }

  Widget _buildUpdateOverlay() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Container(
              margin: EdgeInsets.all(4.w),
              child: Column(
                children: _recentUpdates
                    .take(3)
                    .map((update) => _buildUpdateCard(update))
                    .toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUpdateCard(Map<String, dynamic> update) {
    final title = update['title'] as String;
    final message = update['message'] as String;
    final color = update['color'] as Color;
    final icon = update['icon'] as IconData;

    return Container(
      margin: EdgeInsets.only(bottom: 2.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.9),
            color.withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 6.w,
            ),
          ),
          SizedBox(width: 4.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  message,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12.sp,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              _animationController.reverse().then((_) {
                if (mounted) {
                  setState(() {
                    _recentUpdates.clear();
                  });
                }
              });
            },
            child: Container(
              padding: EdgeInsets.all(1.w),
              child: Icon(
                Icons.close,
                color: Colors.white.withOpacity(0.8),
                size: 5.w,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class OnlineStatusWidget extends StatefulWidget {
  final String userId;
  final Widget Function(bool isOnline, DateTime? lastSeen) builder;

  const OnlineStatusWidget({
    super.key,
    required this.userId,
    required this.builder,
  });

  @override
  State<OnlineStatusWidget> createState() => _OnlineStatusWidgetState();
}

class _OnlineStatusWidgetState extends State<OnlineStatusWidget> {
  late RealtimeUpdateService _realtimeService;
  StreamSubscription<Map<String, dynamic>>? _userStatusSubscription;
  
  bool _isOnline = false;
  DateTime? _lastSeen;

  @override
  void initState() {
    super.initState();
    _initializeStatusTracking();
  }

  void _initializeStatusTracking() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _realtimeService = authProvider.realtimeService;

    // Get initial status
    _loadUserStatus();

    // Subscribe to status updates
    _userStatusSubscription = _realtimeService.userStatusUpdates.listen(
      (update) {
        final userData = update['user_data'] as Map<String, dynamic>?;
        if (userData != null && userData['id'] == widget.userId) {
          setState(() {
            _isOnline = userData['is_online'] as bool? ?? false;
            final lastSeenStr = userData['last_seen'] as String?;
            _lastSeen = lastSeenStr != null ? DateTime.parse(lastSeenStr) : null;
          });
        }
      },
    );
  }

  Future<void> _loadUserStatus() async {
    try {
      final status = await _realtimeService.getUserStatus(widget.userId);
      if (status != null && mounted) {
        setState(() {
          _isOnline = status['is_online'] as bool? ?? false;
          final lastSeenStr = status['last_seen'] as String?;
          _lastSeen = lastSeenStr != null ? DateTime.parse(lastSeenStr) : null;
        });
      }
    } catch (e) {
      print('Error loading user status: $e');
    }
  }

  @override
  void dispose() {
    _userStatusSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(_isOnline, _lastSeen);
  }
}

class TypingIndicatorWidget extends StatefulWidget {
  final String conversationId;

  const TypingIndicatorWidget({
    super.key,
    required this.conversationId,
  });

  @override
  State<TypingIndicatorWidget> createState() => _TypingIndicatorWidgetState();
}

class _TypingIndicatorWidgetState extends State<TypingIndicatorWidget>
    with TickerProviderStateMixin {
  late RealtimeUpdateService _realtimeService;
  late AnimationController _animationController;
  late Animation<double> _animation;
  
  StreamSubscription<List<Map<String, dynamic>>>? _typingSubscription;
  List<String> _typingUsers = [];

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: 0.4,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _initializeTypingIndicator();
  }

  void _initializeTypingIndicator() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _realtimeService = authProvider.realtimeService;

    // Subscribe to typing status
    _typingSubscription = _realtimeService
        .listenToTypingStatus(widget.conversationId)
        .listen((typingData) {
      final currentlyTyping = typingData
          .where((data) => data['is_typing'] == true)
          .map((data) => data['user_id'] as String)
          .toList();

      setState(() {
        _typingUsers = currentlyTyping;
      });
    });
  }

  @override
  void dispose() {
    _typingSubscription?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_typingUsers.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      child: Row(
        children: [
          FadeTransition(
            opacity: _animation,
            child: Text(
              _typingUsers.length == 1
                  ? 'yazıyor...'
                  : '${_typingUsers.length} kişi yazıyor...',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12.sp,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          SizedBox(width: 2.w),
          SizedBox(
            width: 6.w,
            height: 2.h,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(3, (index) {
                return AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    final delay = index * 0.2;
                    final animationValue = (_animationController.value - delay).clamp(0.0, 1.0);
                    
                    return Transform.scale(
                      scale: 0.5 + (animationValue * 0.5),
                      child: Container(
                        width: 1.w,
                        height: 1.w,
                        decoration: BoxDecoration(
                          color: Colors.grey[500],
                          shape: BoxShape.circle,
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}