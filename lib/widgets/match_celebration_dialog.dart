import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../core/app_export.dart';
import '../models/match_proposal.dart';

class MatchCelebrationDialog extends StatefulWidget {
  final MatchProposal matchProposal;
  final UserProfile currentUser;
  final VoidCallback onSendMessage;

  const MatchCelebrationDialog({
    super.key,
    required this.matchProposal,
    required this.currentUser,
    required this.onSendMessage,
  });

  @override
  State<MatchCelebrationDialog> createState() => _MatchCelebrationDialogState();
}

class _MatchCelebrationDialogState extends State<MatchCelebrationDialog>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _fadeController;
  late AnimationController _heartController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _heartAnimation;

  @override
  void initState() {
    super.initState();
    
    _scaleController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    
    _heartController = AnimationController(
      duration: Duration(milliseconds: 1200),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    _heartAnimation = CurvedAnimation(
      parent: _heartController,
      curve: Curves.easeInOut,
    );

    // Start animations
    _scaleController.forward();
    _fadeController.forward();
    _heartController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _fadeController.dispose();
    _heartController.dispose();
    super.dispose();
  }

  String get _otherCandidateName {
    final isDirectCandidate = widget.matchProposal.candidateId == widget.currentUser.id;
    return isDirectCandidate
        ? widget.matchProposal.targetCandidateName ?? 'Eşiniz'
        : widget.matchProposal.candidateName ?? 'Eşiniz';
  }

  String? get _otherCandidateImageUrl {
    final isDirectCandidate = widget.matchProposal.candidateId == widget.currentUser.id;
    return isDirectCandidate
        ? widget.matchProposal.targetCandidateImageUrl
        : widget.matchProposal.candidateImageUrl;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(4.w),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF6C63FF),
                Color(0xFF9C27B0),
                Color(0xFFE91E63),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(51),
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              _buildContent(),
              _buildActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(6.w),
      child: Column(
        children: [
          // Animated hearts
          AnimatedBuilder(
            animation: _heartAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: 1.0 + (_heartAnimation.value * 0.3),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildFloatingHeart(-20, -10),
                    SizedBox(width: 4.w),
                    Icon(
                      Icons.favorite,
                      color: Colors.white,
                      size: 12.w,
                    ),
                    SizedBox(width: 4.w),
                    _buildFloatingHeart(20, -15),
                  ],
                ),
              );
            },
          ),
          SizedBox(height: 3.h),
          // Main title
          FadeTransition(
            opacity: _fadeAnimation,
            child: Text(
              "It's a Match!",
              style: TextStyle(
                fontSize: 28.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [
                  Shadow(
                    color: Colors.black.withAlpha(51),
                    offset: Offset(0, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 1.h),
          FadeTransition(
            opacity: _fadeAnimation,
            child: Text(
              "Siz ve $_otherCandidateName birbirinizi beğendiniz!",
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.white.withAlpha(230),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingHeart(double offsetX, double offsetY) {
    return Transform.translate(
      offset: Offset(offsetX, offsetY),
      child: Icon(
        Icons.favorite,
        color: Colors.pink[200],
        size: 6.w,
      ),
    );
  }

  Widget _buildContent() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w),
      child: Column(
        children: [
          // Profile pictures
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildProfileImage(widget.currentUser.imageUrl, widget.currentUser.fullName),
              SizedBox(width: 8.w),
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(51),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.favorite,
                  color: Colors.white,
                  size: 8.w,
                ),
              ),
              SizedBox(width: 8.w),
              _buildProfileImage(_otherCandidateImageUrl, _otherCandidateName),
            ],
          ),
          SizedBox(height: 4.h),
          // Message
          FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(38),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                "Artık birbirinizle mesajlaşabilir ve daha yakından tanışabilirsiniz!",
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.white.withAlpha(230),
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileImage(String? imageUrl, String name) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white,
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(51),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: CircleAvatar(
        radius: 12.w,
        backgroundColor: Colors.grey[200],
        backgroundImage: imageUrl != null && imageUrl.isNotEmpty
            ? NetworkImage(imageUrl)
            : null,
        child: imageUrl == null || imageUrl.isEmpty
            ? Icon(
                Icons.person,
                color: Colors.grey[400],
                size: 14.w,
              )
            : null,
      ),
    );
  }

  Widget _buildActions() {
    return Container(
      padding: EdgeInsets.all(6.w),
      child: Column(
        children: [
          // Send message button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                widget.onSendMessage();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Color(0xFF6C63FF),
                padding: EdgeInsets.symmetric(vertical: 2.5.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
              ),
              icon: Icon(
                Icons.chat_bubble,
                size: 6.w,
              ),
              label: Text(
                'Mesaj Gönder',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(height: 2.h),
          // Later button
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Daha Sonra',
              style: TextStyle(
                color: Colors.white.withAlpha(179),
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}