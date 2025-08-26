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
      width: 90.w,  // Daha geniş, neredeyse tam ekran
      height: 75.h, // Daha yüksek, dating app tarzı
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24), // Daha büyük radius
        boxShadow: [
          // Ana gölge - daha soft ve doğal
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 30,
            offset: const Offset(0, 10),
            spreadRadius: 0,
          ),
          // Ambient gölge
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 60,
            offset: const Offset(0, 20),
            spreadRadius: -8,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background image
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
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
          // Gradient overlay - Tinder style
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.2),
                  Colors.black.withValues(alpha: 0.9),
                ],
                stops: const [0.0, 0.3, 0.7, 1.0],
              ),
            ),
          ),
          // Profile information - centered name with details below
          Positioned(
            top: 50.h, // Ortada konumlandır
            left: 0,
            right: 0,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Name and Age - centered
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.candidate.fullName.split(' ').first, // Only first name
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32.sp, // Büyük font size
                        fontWeight: FontWeight.w700, // Extra bold
                        letterSpacing: -0.5,
                      ),
                    ),
                    SizedBox(width: 2.w),
                    if (widget.candidate.age != null)
                      Text(
                        '${widget.candidate.age}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7), // Daha transparan
                          fontSize: 32.sp, // Same size as name
                          fontWeight: FontWeight.w400, // Regular weight
                          letterSpacing: -0.5,
                        ),
                      ),
                  ],
                ),
                // Location and Profession - centered and smaller, like in reference image
                SizedBox(height: 1.h),
                Column(
                  children: [
                    if (widget.candidate.location != null)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.location_on,
                            color: Colors.white.withValues(alpha: 0.7),
                            size: 16, // Daha büyük icon
                          ),
                          SizedBox(width: 1.w),
                          Text(
                            widget.candidate.location!,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 11.sp, // Çok küçük
                              fontWeight: FontWeight.w400,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    if (widget.candidate.profession != null) ...[
                      SizedBox(height: 0.2.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.work,
                            color: Colors.white.withValues(alpha: 0.7),
                            size: 16, // Daha büyük icon
                          ),
                          SizedBox(width: 1.w),
                          Text(
                            widget.candidate.profession!,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 11.sp, // Çok küçük
                              fontWeight: FontWeight.w400,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // About dropdown button - top right corner
          if (widget.candidate.bio != null && widget.candidate.bio!.isNotEmpty)
            Positioned(
              top: 4.w,
              right: 4.w,
              child: GestureDetector(
                onTap: () => _showAboutDialog(),
                child: Container(
                  padding: EdgeInsets.all(2.w),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.info_outline,
                    color: Colors.white.withValues(alpha: 0.8),
                    size: 20,
                  ),
                ),
              ),
            ),
          // Bottom interest tags only
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.all(6.w),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Interest tags - much smaller
                  if (widget.candidate.interests != null &&
                      widget.candidate.interests!.isNotEmpty) ...[
                    Wrap(
                      spacing: 1.w,
                      runSpacing: 0.5.h,
                      children:
                          widget.candidate.interests!.take(5).map((interest) {
                        return Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 1.5.w, // Daha küçük padding
                            vertical: 0.3.h,   // Daha küçük padding
                          ),
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(8), // Daha küçük radius
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            interest,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 8.sp, // Çok daha küçük font
                              fontWeight: FontWeight.w300, // Daha ince
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

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          '${widget.candidate.fullName} Hakkında',
          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Container(
          constraints: BoxConstraints(maxHeight: 40.h),
          child: SingleChildScrollView(
            child: Text(
              widget.candidate.bio ?? '',
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                fontSize: 14.sp,
                height: 1.5,
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Kapat',
              style: TextStyle(
                color: AppTheme.lightTheme.primaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
