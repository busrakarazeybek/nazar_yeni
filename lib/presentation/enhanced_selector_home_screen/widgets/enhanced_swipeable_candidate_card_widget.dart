import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class EnhancedSwipeableCandidateCard extends StatefulWidget {
  final UserProfile candidate;
  final UserProfile? selectedCandidate;
  final void Function(String)? onSwipeRight;
  final void Function(String)? onSwipeLeft;
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
  late AnimationController _compatibilityController;
  late Animation<double> _compatibilityAnimation;

  @override
  void initState() {
    super.initState();
    _compatibilityController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _compatibilityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _compatibilityController, curve: Curves.easeOut),
    );

    _compatibilityController.forward();
  }

  @override
  void dispose() {
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

    return Container(
      width: 85.w,
      height: 55.h,
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(6.w),
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
            borderRadius: BorderRadius.circular(6.w),
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
                      AppTheme.lightTheme.colorScheme.surfaceContainerHighest,
                      AppTheme.lightTheme.colorScheme.surfaceContainerHigh,
                    ],
                  ),
                ),
                child: Center(
                  child: CustomIconWidget(
                    iconName: 'person',
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    size: 64.w,
                  ),
                ),
              ),
            ),
          ),
          // Gradient overlay
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6.w),
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
                      color: _getCompatibilityColor(compatibilityScore)
                          .withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(6.w),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
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
                          size: 3.w,
                        ),
                        SizedBox(width: 1.w),
                        Text(
                          '${(compatibilityScore * _compatibilityAnimation.value).round()}%',
                          style: AppTheme.lightTheme.textTheme.labelMedium
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
            bottom: 2.h,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(6.w),
                  bottomRight: Radius.circular(6.w),
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
                          style: AppTheme.lightTheme.textTheme.headlineSmall
                              ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                offset: const Offset(0, 1),
                                blurRadius: 3,
                                color: Colors.black.withValues(alpha: 0.5),
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
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4.w),
                          ),
                          child: Text(
                            '${widget.candidate.age}',
                            style: AppTheme.lightTheme.textTheme.titleMedium
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
                          size: 4.w,
                        ),
                        SizedBox(width: 1.w),
                        Expanded(
                          child: Text(
                            widget.candidate.profession!,
                            style: AppTheme.lightTheme.textTheme.bodyMedium
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
                          size: 4.w,
                        ),
                        SizedBox(width: 1.w),
                        Expanded(
                          child: Text(
                            widget.candidate.location!,
                            style: AppTheme.lightTheme.textTheme.bodyMedium
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
                      children:
                          widget.candidate.interests!.take(3).map((interest) {
                        return Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 2.w,
                            vertical: 0.3.h,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.lightTheme.primaryColor
                                .withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(3.w),
                          ),
                          child: Text(
                            interest,
                            style: AppTheme.lightTheme.textTheme.labelSmall
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
        ],
      ),
    );
  }

  Color _getCompatibilityColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    if (score >= 40) return AppTheme.lightTheme.primaryColor;
    return Colors.red;
  }
}
