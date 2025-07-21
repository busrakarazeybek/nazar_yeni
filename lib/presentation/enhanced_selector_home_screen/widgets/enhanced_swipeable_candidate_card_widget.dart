import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class EnhancedSwipeableCandidateCard extends StatefulWidget {
  final UserProfile candidate;
  final UserProfile? selectedCandidate;
  final VoidCallback? onSwipeRight;
  final VoidCallback? onSwipeLeft;
  final bool isTopCard;

  const EnhancedSwipeableCandidateCard({
    super.key,
    required this.candidate,
    this.selectedCandidate,
    this.onSwipeRight,
    this.onSwipeLeft,
    this.isTopCard = true,
  });

  @override
  State<EnhancedSwipeableCandidateCard> createState() =>
      _EnhancedSwipeableCandidateCardState();
}

class _EnhancedSwipeableCandidateCardState
    extends State<EnhancedSwipeableCandidateCard>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _compatibilityController;
  late Animation<Alignment> _cardAlignmentAnimation;
  late Animation<double> _cardRotationAnimation;
  late Animation<double> _cardScaleAnimation;
  late Animation<double> _compatibilityAnimation;

  Alignment _cardAlignment = Alignment.center;
  double _cardRotation = 0.0;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _compatibilityController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _cardAlignmentAnimation = Tween<Alignment>(
      begin: Alignment.center,
      end: Alignment.center,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    )..addListener(() {
        setState(() {
          _cardAlignment = _cardAlignmentAnimation.value;
        });
      });

    _cardRotationAnimation = Tween<double>(begin: 0.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    )..addListener(() {
        setState(() {
          _cardRotation = _cardRotationAnimation.value;
        });
      });

    _cardScaleAnimation = Tween<double>(begin: 1.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _compatibilityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _compatibilityController, curve: Curves.easeOut),
    );

    // Start compatibility animation
    _compatibilityController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _compatibilityController.dispose();
    super.dispose();
  }

  int _calculateCompatibilityScore() {
    if (widget.selectedCandidate == null) return 0;

    int score = 0;
    final selected = widget.selectedCandidate!;
    final candidate = widget.candidate;

    // Age compatibility
    if (selected.age != null && candidate.age != null) {
      final ageDiff = (selected.age! - candidate.age!).abs();
      score += (10 - ageDiff).clamp(0, 10);
    }

    // Location compatibility
    if (selected.location == candidate.location) {
      score += 20;
    }

    // Interest compatibility
    if (selected.interests != null && candidate.interests != null) {
      final commonInterests = selected.interests!
          .where((interest) => candidate.interests!.contains(interest))
          .length;
      score += commonInterests * 5;
    }

    return (score * 2).clamp(0, 100); // Convert to percentage
  }

  @override
  Widget build(BuildContext context) {
    final compatibilityScore = _calculateCompatibilityScore();

    return Align(
      alignment: _cardAlignment,
      child: Transform.rotate(
        angle: _cardRotation,
        child: AnimatedBuilder(
          animation: _cardScaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _cardScaleAnimation.value,
              child: GestureDetector(
                onPanStart: widget.isTopCard
                    ? (details) {
                        setState(() {
                          _isDragging = true;
                        });
                      }
                    : null,
                onPanUpdate: widget.isTopCard
                    ? (details) {
                        setState(() {
                          _cardAlignment += Alignment(
                            details.delta.dx /
                                (MediaQuery.of(context).size.width / 2),
                            details.delta.dy /
                                (MediaQuery.of(context).size.height / 2),
                          );
                          _cardRotation = _cardAlignment.x * 0.3;
                        });
                      }
                    : null,
                onPanEnd: widget.isTopCard
                    ? (details) {
                        setState(() {
                          _isDragging = false;
                        });

                        // Determine swipe direction
                        if (_cardAlignment.x.abs() > 0.4) {
                          if (_cardAlignment.x > 0) {
                            // Swiped right - like
                            _animateCardOff(Alignment.centerRight);
                            HapticFeedback.mediumImpact();
                            widget.onSwipeRight?.call();
                          } else {
                            // Swiped left - pass
                            _animateCardOff(Alignment.centerLeft);
                            HapticFeedback.lightImpact();
                            widget.onSwipeLeft?.call();
                          }
                        } else {
                          // Snap back to center
                          _animateCardBack();
                        }
                      }
                    : null,
                child: Container(
                  width: 85.w,
                  decoration: BoxDecoration(
                    color: AppTheme.lightTheme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(20.w),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.shadowLight,
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                      BoxShadow(
                        color: AppTheme.shadowLight.withValues(alpha: 0.3),
                        blurRadius: 40,
                        offset: const Offset(0, 16),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Background image
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20.w),
                        child: CustomImageWidget(
                          imageUrl: widget.candidate.imageUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorWidget: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppTheme.lightTheme.colorScheme
                                      .surfaceContainerHighest,
                                  AppTheme.lightTheme.colorScheme
                                      .surfaceContainerHigh,
                                ],
                              ),
                            ),
                            child: Center(
                              child: CustomIconWidget(
                                iconName: 'person',
                                color: AppTheme
                                    .lightTheme.colorScheme.onSurfaceVariant,
                                size: 64.w,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Gradient overlay
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20.w),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.1),
                              Colors.black.withValues(alpha: 0.8),
                            ],
                            stops: const [0.0, 0.6, 1.0],
                          ),
                        ),
                      ),
                      // Compatibility indicator
                      if (widget.selectedCandidate != null)
                        Positioned(
                          top: 4.w,
                          right: 4.w,
                          child: AnimatedBuilder(
                            animation: _compatibilityAnimation,
                            builder: (context, child) {
                              return Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 3.w,
                                  vertical: 1.h,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      _getCompatibilityColor(compatibilityScore)
                                          .withValues(alpha: 0.9),
                                  borderRadius: BorderRadius.circular(6.w),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.2),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CustomIconWidget(
                                      iconName: 'favorite',
                                      color: Colors.white,
                                      size: 12.w,
                                    ),
                                    SizedBox(width: 1.w),
                                    Text(
                                      '${(compatibilityScore * _compatibilityAnimation.value).round()}%',
                                      style: AppTheme
                                          .lightTheme.textTheme.labelMedium
                                          ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      // Profile information
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: EdgeInsets.all(4.w),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(20.w),
                              bottomRight: Radius.circular(20.w),
                            ),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.3),
                              ],
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      widget.candidate.fullName,
                                      style: AppTheme
                                          .lightTheme.textTheme.headlineSmall
                                          ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        shadows: [
                                          Shadow(
                                            offset: const Offset(0, 1),
                                            blurRadius: 3,
                                            color: Colors.black
                                                .withValues(alpha: 0.5),
                                          ),
                                        ],
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (widget.candidate.age != null)
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 2.w,
                                        vertical: 0.5.h,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            Colors.white.withValues(alpha: 0.2),
                                        borderRadius:
                                            BorderRadius.circular(4.w),
                                      ),
                                      child: Text(
                                        '${widget.candidate.age}',
                                        style: AppTheme
                                            .lightTheme.textTheme.titleMedium
                                            ?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              if (widget.candidate.profession != null) ...[
                                SizedBox(height: 0.5.h),
                                Row(
                                  children: [
                                    CustomIconWidget(
                                      iconName: 'work',
                                      color: Colors.white70,
                                      size: 16.w,
                                    ),
                                    SizedBox(width: 1.w),
                                    Expanded(
                                      child: Text(
                                        widget.candidate.profession!,
                                        style: AppTheme
                                            .lightTheme.textTheme.bodyMedium
                                            ?.copyWith(
                                          color: Colors.white70,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              if (widget.candidate.location != null) ...[
                                SizedBox(height: 0.5.h),
                                Row(
                                  children: [
                                    CustomIconWidget(
                                      iconName: 'location_on',
                                      color: Colors.white70,
                                      size: 16.w,
                                    ),
                                    SizedBox(width: 1.w),
                                    Expanded(
                                      child: Text(
                                        widget.candidate.location!,
                                        style: AppTheme
                                            .lightTheme.textTheme.bodyMedium
                                            ?.copyWith(
                                          color: Colors.white70,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              if (widget.candidate.interests != null &&
                                  widget.candidate.interests!.isNotEmpty) ...[
                                SizedBox(height: 1.h),
                                Wrap(
                                  spacing: 1.w,
                                  runSpacing: 0.5.h,
                                  children: widget.candidate.interests!
                                      .take(3)
                                      .map((interest) {
                                    return Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 2.w,
                                        vertical: 0.3.h,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.lightTheme.primaryColor
                                            .withValues(alpha: 0.8),
                                        borderRadius:
                                            BorderRadius.circular(3.w),
                                      ),
                                      child: Text(
                                        interest,
                                        style: AppTheme
                                            .lightTheme.textTheme.labelSmall
                                            ?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      // Swipe indicators
                      if (_isDragging && widget.isTopCard) ...[
                        // Right swipe indicator (green heart)
                        if (_cardAlignment.x > 0.1)
                          Positioned(
                            top: 15.h,
                            right: 4.w,
                            child: Transform.rotate(
                              angle: -0.3,
                              child: Container(
                                padding: EdgeInsets.all(4.w),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.green.withValues(alpha: 0.5),
                                      blurRadius: 16,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: CustomIconWidget(
                                  iconName: 'favorite',
                                  color: Colors.white,
                                  size: 32.w,
                                ),
                              ),
                            ),
                          ),
                        // Left swipe indicator (red X)
                        if (_cardAlignment.x < -0.1)
                          Positioned(
                            top: 15.h,
                            left: 4.w,
                            child: Transform.rotate(
                              angle: 0.3,
                              child: Container(
                                padding: EdgeInsets.all(4.w),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.red.withValues(alpha: 0.5),
                                      blurRadius: 16,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: CustomIconWidget(
                                  iconName: 'close',
                                  color: Colors.white,
                                  size: 32.w,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Color _getCompatibilityColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    if (score >= 40) return AppTheme.lightTheme.primaryColor;
    return Colors.red;
  }

  void _animateCardOff(Alignment alignment) {
    _cardAlignmentAnimation = Tween<Alignment>(
      begin: _cardAlignment,
      end: alignment * 3,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _cardRotationAnimation = Tween<double>(
      begin: _cardRotation,
      end: alignment.x > 0 ? 0.5 : -0.5,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _cardScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.7,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
  }

  void _animateCardBack() {
    _cardAlignmentAnimation = Tween<Alignment>(
      begin: _cardAlignment,
      end: Alignment.center,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _cardRotationAnimation = Tween<double>(
      begin: _cardRotation,
      end: 0.0,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _cardScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _animationController.forward();
  }
}
