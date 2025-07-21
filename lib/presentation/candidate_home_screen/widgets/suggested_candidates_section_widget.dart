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
        CustomIconWidget(
          iconName: 'person_search',
          color: AppTheme.lightTheme.primaryColor,
          size: 24.w,
        ),
        SizedBox(width: 2.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Önerilen Adaylar',
                style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 15,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Candidate info section
          Padding(
            padding: EdgeInsets.all(4.w),
            child: Column(
              children: [
                _buildCandidateHeader(proposal),
                SizedBox(height: 2.h),
                // Bilgi mesajı
                Align(
                  alignment: Alignment.centerLeft,
                  child: isDirectCandidate
                      ? Text(
                          '${proposal.selectorName ?? 'Bir seçici'} senin için önerdi',
                          style: TextStyle(
                            color: AppTheme.lightTheme.primaryColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 12.sp,
                          ),
                        )
                      : SizedBox
                          .shrink(), // target_candidate ise seçici adı gösterme
                ),
                SizedBox(height: 1.h),
                _buildCandidateInfo(
                  name: otherCandidateName,
                  imageUrl: otherCandidateImage,
                  bio: otherCandidateBio,
                ),
                SizedBox(height: 2.h),
                _buildCompatibilityHighlights(),
              ],
            ),
          ),

          // Action buttons
          _buildActionButtons(proposal),

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
}
