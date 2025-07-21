import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class SwipeableCandidateCard extends StatefulWidget {
  final UserProfile candidate;
  final VoidCallback? onSwipeRight;
  final VoidCallback? onSwipeLeft;

  const SwipeableCandidateCard({
    super.key,
    required this.candidate,
    this.onSwipeRight,
    this.onSwipeLeft,
  });

  @override
  State<SwipeableCandidateCard> createState() => _SwipeableCandidateCardState();
}

class _SwipeableCandidateCardState extends State<SwipeableCandidateCard>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Alignment> _cardAlignmentAnimation;
  late Animation<double> _cardRotationAnimation;
  late Animation<double> _cardScaleAnimation;

  Alignment _cardAlignment = Alignment.center;
  double _cardRotation = 0.0;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
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
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                onPanStart: (details) {
                  setState(() {
                    _isDragging = true;
                  });
                },
                onPanUpdate: (details) {
                  setState(() {
                    _cardAlignment += Alignment(
                      details.delta.dx /
                          (MediaQuery.of(context).size.width / 2),
                      details.delta.dy /
                          (MediaQuery.of(context).size.height / 2),
                    );
                    _cardRotation = _cardAlignment.x * 0.3;
                  });
                },
                onPanEnd: (details) {
                  setState(() {
                    _isDragging = false;
                  });

                  // Determine swipe direction
                  if (_cardAlignment.x.abs() > 0.5) {
                    if (_cardAlignment.x > 0) {
                      // Swiped right - like
                      _animateCardOff(Alignment.centerRight);
                      HapticFeedback.lightImpact();
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
                },
                child: Container(
                  width: 85.w,
                  height: 60.h,
                  decoration: BoxDecoration(
                    color: AppTheme.lightTheme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(16.w),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.shadowLight,
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Background image
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16.w),
                        child: CustomImageWidget(
                          imageUrl: widget.candidate.imageUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorWidget: Container(
                            color: AppTheme
                                .lightTheme.colorScheme.surfaceContainerHighest,
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
                          borderRadius: BorderRadius.circular(16.w),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.7),
                            ],
                            stops: const [0.5, 1.0],
                          ),
                        ),
                      ),
                      // Profile information
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: EdgeInsets.all(4.w),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.candidate.fullName,
                                style: AppTheme
                                    .lightTheme.textTheme.headlineSmall
                                    ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (widget.candidate.age != null) ...[
                                SizedBox(height: 0.5.h),
                                Text(
                                  '${widget.candidate.age} yaş',
                                  style: AppTheme
                                      .lightTheme.textTheme.titleMedium
                                      ?.copyWith(
                                    color: Colors.white70,
                                  ),
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
                              if (widget.candidate.bio != null &&
                                  widget.candidate.bio!.isNotEmpty) ...[
                                SizedBox(height: 1.h),
                                Text(
                                  widget.candidate.bio!,
                                  style: AppTheme.lightTheme.textTheme.bodySmall
                                      ?.copyWith(
                                    color: Colors.white70,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      // Swipe indicators
                      if (_isDragging) ...[
                        // Right swipe indicator (green heart)
                        if (_cardAlignment.x > 0.1)
                          Positioned(
                            top: 10.h,
                            right: 4.w,
                            child: Container(
                              padding: EdgeInsets.all(3.w),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.8),
                                shape: BoxShape.circle,
                              ),
                              child: CustomIconWidget(
                                iconName: 'favorite',
                                color: Colors.white,
                                size: 32.w,
                              ),
                            ),
                          ),
                        // Left swipe indicator (red X)
                        if (_cardAlignment.x < -0.1)
                          Positioned(
                            top: 10.h,
                            left: 4.w,
                            child: Container(
                              padding: EdgeInsets.all(3.w),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.8),
                                shape: BoxShape.circle,
                              ),
                              child: CustomIconWidget(
                                iconName: 'close',
                                color: Colors.white,
                                size: 32.w,
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

  void _animateCardOff(Alignment alignment) {
    _cardAlignmentAnimation = Tween<Alignment>(
      begin: _cardAlignment,
      end: alignment * 2,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _cardRotationAnimation = Tween<double>(
      begin: _cardRotation,
      end: alignment.x > 0 ? 0.3 : -0.3,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _cardScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.8,
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
