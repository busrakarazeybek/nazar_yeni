import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../models/match_proposal.dart';
import '../../../widgets/custom_swipeable_card_widget.dart';

class SuggestedCandidatesSection extends StatefulWidget {
  final List<MatchProposal> proposals;
  final UserProfile? selectedSelector;
  final Function(MatchProposal) onAcceptProposal;
  final Function(MatchProposal) onRejectProposal;
  final Function(MatchProposal) onViewProfile;
  final UserProfile currentUser; // yeni parametre

  const SuggestedCandidatesSection({
    super.key,
    required this.proposals,
    required this.selectedSelector,
    required this.onAcceptProposal,
    required this.onRejectProposal,
    required this.onViewProfile,
    required this.currentUser,
  });

  @override
  State<SuggestedCandidatesSection> createState() =>
      _SuggestedCandidatesSectionState();
}

class _SuggestedCandidatesSectionState
    extends State<SuggestedCandidatesSection> {
  bool _isProcessing = false;
  MatchProposal? _processingProposal;
  late List<MatchProposal> _localProposals;

  @override
  void initState() {
    super.initState();
    _localProposals = List.from(widget.proposals);
  }

  @override
  void didUpdateWidget(covariant SuggestedCandidatesSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.proposals != widget.proposals) {
      _localProposals = List.from(widget.proposals);
    }
  }

  void _handleAccept(MatchProposal proposal) async {
    setState(() {
      _isProcessing = true;
      _processingProposal = proposal;
    });
    try {
      await widget.onAcceptProposal(proposal);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Öneri kabul edildi!'),
            backgroundColor: Colors.green,
          ),
        );
      }
      setState(() {
        _localProposals.remove(proposal);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kabul işlemi başarısız: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isProcessing = false;
        _processingProposal = null;
      });
    }
  }

  void _handleReject(MatchProposal proposal) async {
    setState(() {
      _isProcessing = true;
      _processingProposal = proposal;
    });
    try {
      await widget.onRejectProposal(proposal);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Öneri reddedildi!'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      setState(() {
        _localProposals.remove(proposal);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Red işlemi başarısız: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isProcessing = false;
        _processingProposal = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.selectedSelector == null) {
      return _buildNoSelectorSelected();
    }

    if (_localProposals.isEmpty) {
      return _buildNoSuggestions();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(),
        SizedBox(height: 2.h),
        SizedBox(
          height: 52.h,
          child: CustomSwipeableCard(
            cards: _localProposals
                .map((proposal) => _buildCandidateCard(proposal))
                .toList(),
            onSwipe: (direction, index) {
              if (index >= _localProposals.length) return;
              final proposal = _localProposals[index];
              if (direction == SwipeDirection.right) {
                _handleAccept(proposal);
              } else if (direction == SwipeDirection.left) {
                _handleReject(proposal);
              }
            },
            swipeThreshold: 0.3,
            stackSize: 3,
            cardPadding: EdgeInsets.all(8.0),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader() {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(2.w),
          decoration: BoxDecoration(
            color: AppTheme.lightTheme.primaryColor.withAlpha(26),
            borderRadius: BorderRadius.circular(8),
          ),
          child: CustomIconWidget(
            iconName: 'person_search',
            color: AppTheme.lightTheme.primaryColor,
            size: 5.w,
          ),
        ),
        SizedBox(width: 2.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Önerilen Adaylar',
                style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.lightTheme.colorScheme.onSurface,
                ),
              ),
              Text(
                '${widget.selectedSelector!.fullName} tarafından',
                style: TextStyle(color: Colors.grey[600], fontSize: 11.sp),
              ),
            ],
          ),
        ),
        Text(
          '${widget.proposals.length} öneri',
          style: TextStyle(color: Colors.grey[600], fontSize: 11.sp),
        ),
      ],
    );
  }

  Widget _buildCandidateCard(MatchProposal proposal) {
    final isDirectCandidate = proposal.candidateId == widget.currentUser.id;
    final otherCandidateName = isDirectCandidate
        ? proposal.targetCandidateName ?? 'Bilinmeyen Aday'
        : proposal.candidateName ?? 'Bilinmeyen Aday';
    final otherCandidateImage = isDirectCandidate
        ? proposal.targetCandidateImageUrl
        : proposal.candidateImageUrl;
    final otherCandidateBio =
        isDirectCandidate ? proposal.targetCandidateBio : proposal.candidateBio;

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      width: 85.w,
      height: 65.h, // Sabit yükseklik
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
              imageUrl: otherCandidateImage,
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
          // Selector info badge
          if (isDirectCandidate)
            Positioned(
              top: 4.w,
              right: 4.w,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 3.w,
                  vertical: 1.h,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.primaryColor.withValues(alpha: 0.9),
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
                      iconName: 'person_search',
                      color: Colors.white,
                      size: 12.w,
                    ),
                    SizedBox(width: 1.w),
                    Text(
                      '${proposal.selectorName ?? 'Seçici'}',
                      style: AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
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
                  Text(
                    otherCandidateName,
                    style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
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
                  if (otherCandidateBio != null && otherCandidateBio!.isNotEmpty) ...[
                    SizedBox(height: 0.5.h),
                    Text(
                      otherCandidateBio!,
                      style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  SizedBox(height: 2.h),
                  // Action buttons
                  _buildEnhancedActionButtons(proposal),
                ],
              ),
            ),
          ),

          // Karşılıklı onayda mesajlaşma butonu
          if (proposal.status == AcceptanceStatus.accepted &&
              proposal.targetStatus == AcceptanceStatus.accepted)
            Padding(
              padding: EdgeInsets.only(bottom: 2.h),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.chatScreen,
                    arguments: {
                      'matchId': proposal.id,
                      'partnerName': proposal.targetCandidateName ??
                          proposal.candidateName,
                      'partnerImageUrl': proposal.targetCandidateImageUrl ??
                          proposal.candidateImageUrl,
                    },
                  );
                },
                icon: Icon(Icons.chat),
                label: Text('Mesajlaşmaya Başla'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.lightTheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCandidateHeader(MatchProposal proposal) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
          decoration: BoxDecoration(
            color: AppTheme.lightTheme.primaryColor.withAlpha(26),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomIconWidget(
                iconName: 'favorite',
                color: AppTheme.lightTheme.primaryColor,
                size: 14.w,
              ),
              SizedBox(width: 1.w),
              Text(
                'Eşleşme Önerisi',
                style: TextStyle(
                  color: AppTheme.lightTheme.primaryColor,
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Spacer(),
        Text(
          _formatDate(proposal.createdAt),
          style: TextStyle(color: Colors.grey[600], fontSize: 10.sp),
        ),
      ],
    );
  }

  Widget _buildCandidateInfo({
    required String name,
    String? imageUrl,
    String? bio,
  }) {
    return Row(
      children: [
        CircleAvatar(
          radius: 30.w,
          backgroundColor: Colors.grey[200],
          child: imageUrl != null
              ? CustomImageWidget(
                  imageUrl: imageUrl,
                  height: 60.w,
                  width: 60.w,
                  fit: BoxFit.cover,
                )
              : CustomIconWidget(
                  iconName: 'person',
                  color: Colors.grey[400]!,
                  size: 35.w,
                ),
        ),
        SizedBox(width: 4.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 1.h),
              if (bio != null && bio.isNotEmpty)
                Text(
                  bio,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompatibilityHighlights() {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.green.withAlpha(26),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CustomIconWidget(
            iconName: 'psychology',
            color: Colors.green,
            size: 20.w,
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Uyumluluk Sebepleri',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.green[700],
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  '${widget.selectedSelector!.fullName} size bu adayı önerdi çünkü...',
                  style: TextStyle(fontSize: 11.sp, color: Colors.green[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(MatchProposal proposal) {
    final canRespond = proposal.isPending;
    final isCurrentProcessing =
        _isProcessing && _processingProposal == proposal;

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          if (canRespond) ...[
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isCurrentProcessing
                        ? null
                        : () => _handleAccept(proposal),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 2.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: isCurrentProcessing
                        ? SizedBox(
                            width: 18.w,
                            height: 18.w,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : CustomIconWidget(
                            iconName: 'check',
                            color: Colors.white,
                            size: 18.w,
                          ),
                    label: Text(
                      'Öneriyi Kabul Et',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isCurrentProcessing
                        ? null
                        : () => _handleReject(proposal),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: BorderSide(color: Colors.red),
                      padding: EdgeInsets.symmetric(vertical: 2.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: CustomIconWidget(
                      iconName: 'close',
                      color: Colors.red,
                      size: 18.w,
                    ),
                    label: Text(
                      'Reddet',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
          ],
          OutlinedButton.icon(
            onPressed: () => widget.onViewProfile(proposal),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.lightTheme.primaryColor,
              side: BorderSide(color: AppTheme.lightTheme.primaryColor),
              minimumSize: Size(double.infinity, 6.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: CustomIconWidget(
              iconName: 'visibility',
              color: AppTheme.lightTheme.primaryColor,
              size: 18.w,
            ),
            label: Text(
              'Profili Görüntüle',
              style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoSelectorSelected() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(6.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: 'touch_app',
              color: Colors.grey[400]!,
              size: 48.w,
            ),
            SizedBox(height: 2.h),
            Text(
              'Görücü Seçin',
              style: AppTheme.lightTheme.textTheme.titleMedium,
            ),
            SizedBox(height: 1.h),
            Text(
              'Önerilen adayları görmek için yukarıdan bir görücü seçin.',
              style: TextStyle(color: Colors.grey[600], fontSize: 12.sp),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoSuggestions() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(6.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: 'search_off',
              color: Colors.grey[400]!,
              size: 48.w,
            ),
            SizedBox(height: 2.h),
            Text(
              'Henüz Öneri Yok',
              style: AppTheme.lightTheme.textTheme.titleMedium,
            ),
            SizedBox(height: 1.h),
            Text(
              '${widget.selectedSelector!.fullName} henüz size bir aday önermedi.',
              style: TextStyle(color: Colors.grey[600], fontSize: 12.sp),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} gün önce';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} saat önce';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} dakika önce';
    } else {
      return 'Az önce';
    }
  }

  Widget _buildEnhancedActionButtons(MatchProposal proposal) {
    return Row(
      children: [
        // Reddet butonu
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
            heroTag: "reject_${proposal.id}",
            mini: true,
            onPressed: () => widget.onRejectProposal(proposal),
            backgroundColor: Colors.red,
            elevation: 0,
            child: Icon(
              Icons.close_rounded,
              color: Colors.white,
              size: 6.w,
            ),
          ),
        ),
        SizedBox(width: 3.w),
        // Nazar boncuğu ikonu (orta)
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: FloatingActionButton(
            heroTag: "nazar_${proposal.id}",
            mini: true,
            onPressed: () {}, // Boş fonksiyon - sadece dekoratif
            backgroundColor: Colors.blue[700],
            elevation: 0,
            child: Icon(
              Icons.remove_red_eye,
              color: Colors.white,
              size: 5.w,
            ),
          ),
        ),
        SizedBox(width: 3.w),
        // Kabul et butonu
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
            heroTag: "accept_${proposal.id}",
            mini: true,
            onPressed: () => widget.onAcceptProposal(proposal),
            backgroundColor: Colors.green,
            elevation: 0,
            child: Icon(
              Icons.favorite_rounded,
              color: Colors.white,
              size: 6.w,
            ),
          ),
        ),
      ],
      mainAxisAlignment: MainAxisAlignment.center,
    );
  }
}
