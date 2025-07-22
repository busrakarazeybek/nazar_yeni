import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import './enhanced_swipeable_candidate_card_widget.dart';
import './preferences_context_widget.dart';

class EnhancedPotentialMatchesSection extends StatefulWidget {
  final List<UserProfile> potentialMatches;
  final UserProfile? selectedCandidate;
  final VoidCallback onRefresh;
  final Function(UserProfile)? onMatchProposal;
  final Function(UserProfile, bool isRightSwipe)? onCardSwiped;

  const EnhancedPotentialMatchesSection({
    super.key,
    required this.potentialMatches,
    required this.selectedCandidate,
    required this.onRefresh,
    this.onMatchProposal,
    this.onCardSwiped,
  });

  @override
  State<EnhancedPotentialMatchesSection> createState() =>
      _EnhancedPotentialMatchesSectionState();
}

class _EnhancedPotentialMatchesSectionState
    extends State<EnhancedPotentialMatchesSection> {
  UserProfile? currentTopCandidate;

  @override
  void didUpdateWidget(covariant EnhancedPotentialMatchesSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.potentialMatches.isNotEmpty) {
      if (currentTopCandidate == null ||
          widget.potentialMatches.first.id != currentTopCandidate!.id) {
        setState(() {
          currentTopCandidate = widget.potentialMatches.first;
        });
      }
    } else {
      setState(() {
        currentTopCandidate = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(context),
          SizedBox(height: 2.h),
          PreferencesContextWidget(selectedCandidate: widget.selectedCandidate),
          SizedBox(height: 2.h),
          widget.selectedCandidate == null
              ? _buildSelectionPrompt(context)
              : _buildSwipeableCards(context),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(1.2.w),
          decoration: BoxDecoration(
            color: AppTheme.lightTheme.primaryColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(5),
          ),
          child: CustomIconWidget(
            iconName: 'group',
            color: AppTheme.lightTheme.primaryColor,
            size: 18,
          ),
        ),
        SizedBox(width: 1.5.w),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.selectedCandidate != null
                  ? 'Tercih Edilen Adaylar'
                  : 'Potansiyel Eşleşmeler',
              style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.lightTheme.colorScheme.onSurface,
                fontSize: 15,
              ),
            ),
            if (widget.selectedCandidate != null)
              Text(
                '${widget.selectedCandidate!.fullName} için uygun adaylar',
                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildSelectionPrompt(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(6.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.lightTheme.colorScheme.surface,
            AppTheme.lightTheme.colorScheme.surface.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16.w),
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowLight,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: CustomIconWidget(
                iconName: 'person_search',
                color: AppTheme.lightTheme.primaryColor,
                size: 48.w,
              ),
            ),
            SizedBox(height: 3.h),
            Text(
              'Kimin için eşleştirme yapacaksınız?',
              style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 1.h),
            Text(
              'Yukarıdaki listeden bir kişi seçin, onun tercihlerine göre uygun adayları kaydırarak eşleştirme yapabilirsiniz',
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 2.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.w),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomIconWidget(
                    iconName: 'swipe',
                    color: AppTheme.lightTheme.primaryColor,
                    size: 16.w,
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    'Sağa kaydır: Eşleştir  •  Sola kaydır: Geç',
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.lightTheme.primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwipeableCards(BuildContext context) {
    if (widget.potentialMatches.isEmpty) {
      return _buildEmptyMatches(context);
    }

    final topCandidate = currentTopCandidate ?? widget.potentialMatches.first;

    return SizedBox(
      height: 70.h,
      child: Stack(
        children: [
          ...List.generate(widget.potentialMatches.length.clamp(0, 3), (index) {
            final candidate = widget.potentialMatches[index];
            final scale = 1.0 - (index * 0.05);
            final offset = index * 8.0;

            return Positioned(
              top: offset,
              left: index * 4.0,
              right: index * 4.0,
              bottom: offset * 2,
              child: Transform.scale(
                scale: scale,
                child: EnhancedSwipeableCandidateCard(
                  candidate: candidate,
                  selectedCandidate: widget.selectedCandidate,
                  onSwipeRight: index == 0
                      ? (c) {
                          if (widget.onCardSwiped != null) {
                            widget.onCardSwiped!(c, true);
                          }
                          _updateTopCandidate();
                        }
                      : null,
                  onSwipeLeft: index == 0
                      ? (c) {
                          if (widget.onCardSwiped != null) {
                            widget.onCardSwiped!(c, false);
                          }
                          _updateTopCandidate();
                        }
                      : null,
                  isTopCard: index == 0,
                ),
              ),
            );
          }),
          Positioned(
            bottom: 2.h,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Pass button
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: FloatingActionButton(
                    heroTag: "pass",
                    onPressed: () {
                      if (topCandidate != null && widget.onCardSwiped != null) {
                        widget.onCardSwiped!(topCandidate, false);
                      }
                      _updateTopCandidate();
                    },
                    backgroundColor: Colors.red,
                    elevation: 0,
                    child: CustomIconWidget(
                      iconName: 'close',
                      color: Colors.white,
                      size: 24.w,
                    ),
                  ),
                ),
                // Info button
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.lightTheme.primaryColor.withValues(
                          alpha: 0.3,
                        ),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: FloatingActionButton(
                    heroTag: "info",
                    mini: true,
                    onPressed: () {},
                    backgroundColor: AppTheme.lightTheme.primaryColor,
                    elevation: 0,
                    child: CustomIconWidget(
                      iconName: 'info',
                      color: Colors.white,
                      size: 16.w,
                    ),
                  ),
                ),
                // Like button
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: FloatingActionButton(
                    heroTag: "like",
                    onPressed: () {
                      if (topCandidate != null && widget.onCardSwiped != null) {
                        widget.onCardSwiped!(topCandidate, true);
                      }
                      _updateTopCandidate();
                    },
                    backgroundColor: Colors.green,
                    elevation: 0,
                    child: CustomIconWidget(
                      iconName: 'favorite',
                      color: Colors.white,
                      size: 24.w,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _updateTopCandidate() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.potentialMatches.isNotEmpty) {
        setState(() {
          currentTopCandidate = widget.potentialMatches.first;
        });
      } else {
        setState(() {
          currentTopCandidate = null;
        });
      }
    });
  }

  void _showCandidateDetails(BuildContext context, UserProfile candidate) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 60.h,
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.surface,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20.w),
            topRight: Radius.circular(20.w),
          ),
        ),
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 12.w,
                height: 0.5.h,
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.colorScheme.outline,
                  borderRadius: BorderRadius.circular(2.w),
                ),
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              candidate.fullName,
              style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 1.h),
            if (candidate.bio != null)
              Text(
                candidate.bio!,
                style: AppTheme.lightTheme.textTheme.bodyMedium,
              ),
            // Add more candidate details here
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyMatches(BuildContext context) {
    return Container(
      height: 30.h,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16.w),
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: 'search_off',
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              size: 48.w,
            ),
            SizedBox(height: 2.h),
            Text(
              'Tercih edilen kriterlere uygun aday yok',
              style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Farklı bir aday seçin veya tercihleri değiştirmek için aday ile iletişime geçin',
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoMoreCards() {
    return Container(
      height: 40.h,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.lightTheme.primaryColor.withValues(alpha: 0.05),
            AppTheme.lightTheme.primaryColor.withValues(alpha: 0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(16.w),
        border: Border.all(
          color: AppTheme.lightTheme.primaryColor.withValues(alpha: 0.2),
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: CustomIconWidget(
                iconName: 'check_circle',
                color: AppTheme.lightTheme.primaryColor,
                size: 48.w,
              ),
            ),
            SizedBox(height: 3.h),
            Text(
              'Tercih edilen tüm adayları gözden geçirdiniz!',
              style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Farklı bir aday seçin veya yeni adaylar için sayfayı yenileyin',
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 3.h),
            ElevatedButton.icon(
              onPressed: widget.onRefresh,
              icon: CustomIconWidget(
                iconName: 'refresh',
                color: Colors.white,
                size: 16.w,
              ),
              label: const Text('Yeni Adayları Getir'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.lightTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.w),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
