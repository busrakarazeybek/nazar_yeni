import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import './swipeable_candidate_card_widget.dart';

class PotentialMatchesSection extends StatefulWidget {
  final List<UserProfile> potentialMatches;
  final UserProfile? selectedCandidate;
  final VoidCallback onRefresh;
  final Function(UserProfile, UserProfile)? onMatchRequest;

  const PotentialMatchesSection({
    super.key,
    required this.potentialMatches,
    required this.selectedCandidate,
    required this.onRefresh,
    this.onMatchRequest,
  });

  @override
  State<PotentialMatchesSection> createState() =>
      _PotentialMatchesSectionState();
}

class _PotentialMatchesSectionState extends State<PotentialMatchesSection> {
  late List<UserProfile> _currentMatches;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _updateMatches();
  }

  @override
  void didUpdateWidget(PotentialMatchesSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.potentialMatches != widget.potentialMatches ||
        oldWidget.selectedCandidate != widget.selectedCandidate) {
      _updateMatches();
    }
  }

  void _updateMatches() {
    // Filter out the selected candidate from potential matches
    _currentMatches = widget.potentialMatches
        .where((match) => match.id != widget.selectedCandidate?.id)
        .toList();
    _currentIndex = 0;
  }

  void _onSwipeRight(UserProfile candidate) {
    if (widget.selectedCandidate != null) {
      HapticFeedback.lightImpact();
      widget.onMatchRequest?.call(widget.selectedCandidate!, candidate);
    }
    _nextCard();
  }

  void _onSwipeLeft(UserProfile candidate) {
    HapticFeedback.lightImpact();
    _nextCard();
  }

  void _nextCard() {
    setState(() {
      if (_currentIndex < _currentMatches.length - 1) {
        _currentIndex++;
      } else {
        // No more cards, refresh
        widget.onRefresh();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CustomIconWidget(
                    iconName: 'group',
                    color: AppTheme.lightTheme.primaryColor,
                    size: 20.w,
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      widget.selectedCandidate != null
                          ? '${widget.selectedCandidate!.fullName} için adaylar:'
                          : 'Potansiyel eşleşmeler:',
                      style:
                          AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.lightTheme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: widget.onRefresh,
                icon: CustomIconWidget(
                  iconName: 'refresh',
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  size: 20.w,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          widget.selectedCandidate == null
              ? _buildSelectionPrompt()
              : _buildSwipeableCards(),
        ],
      ),
    );
  }

  Widget _buildSelectionPrompt() {
    return Container(
      padding: EdgeInsets.all(6.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12.w),
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.2),
          style: BorderStyle.solid,
        ),
      ),
      child: Center(
        child: Column(
          children: [
            CustomIconWidget(
              iconName: 'person_search',
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              size: 48.w,
            ),
            SizedBox(height: 2.h),
            Text(
              'Yukarıdan "Seçilecekler" bölümünden bir kişi seçin',
              style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 1.h),
            Text(
              'Seçtiğiniz kişi için uygun adayları kaydırarak eşleştirme yapabilirsiniz',
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

  Widget _buildSwipeableCards() {
    if (_currentMatches.isEmpty) {
      return _buildEmptyMatches();
    }

    if (_currentIndex >= _currentMatches.length) {
      return _buildNoMoreCards();
    }

    return SizedBox(
      height: 65.h,
      child: Stack(
        children: [
          // Show next card behind current card for smooth transition
          if (_currentIndex + 1 < _currentMatches.length)
            Positioned.fill(
              child: Transform.scale(
                scale: 0.95,
                child: SwipeableCandidateCard(
                  candidate: _currentMatches[_currentIndex + 1],
                ),
              ),
            ),
          // Current card
          Positioned.fill(
            child: SwipeableCandidateCard(
              candidate: _currentMatches[_currentIndex],
              onSwipeRight: () => _onSwipeRight(_currentMatches[_currentIndex]),
              onSwipeLeft: () => _onSwipeLeft(_currentMatches[_currentIndex]),
            ),
          ),
          // Action buttons at the bottom
          Positioned(
            bottom: 2.h,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Pass button
                FloatingActionButton(
                  heroTag: "pass",
                  onPressed: () => _onSwipeLeft(_currentMatches[_currentIndex]),
                  backgroundColor: Colors.red,
                  child: CustomIconWidget(
                    iconName: 'close',
                    color: Colors.white,
                    size: 24.w,
                  ),
                ),
                // Like button
                FloatingActionButton(
                  heroTag: "like",
                  onPressed: () =>
                      _onSwipeRight(_currentMatches[_currentIndex]),
                  backgroundColor: Colors.green,
                  child: CustomIconWidget(
                    iconName: 'favorite',
                    color: Colors.white,
                    size: 24.w,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyMatches() {
    return Container(
      height: 20.h,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12.w),
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.2),
          style: BorderStyle.solid,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: 'search_off',
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              size: 32.w,
            ),
            SizedBox(height: 2.h),
            Text(
              'Henüz uygun aday yok',
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoMoreCards() {
    return Container(
      height: 30.h,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12.w),
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.2),
          style: BorderStyle.solid,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: 'check_circle',
              color: AppTheme.lightTheme.primaryColor,
              size: 48.w,
            ),
            SizedBox(height: 2.h),
            Text(
              'Tüm adayları gözden geçirdiniz!',
              style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Yeni adaylar için sayfayı yenileyin',
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 2.h),
            ElevatedButton.icon(
              onPressed: widget.onRefresh,
              icon: CustomIconWidget(
                iconName: 'refresh',
                color: Colors.white,
                size: 16.w,
              ),
              label: Text('Yenile'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.lightTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
