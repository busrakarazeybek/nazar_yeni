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
    extends State<SuggestedCandidatesSection> with TickerProviderStateMixin {
  bool _isProcessing = false;
  MatchProposal? _processingProposal;
  late List<MatchProposal> _localProposals;
  Set<String> _nazerBoncuguPressed = {}; // Nazar boncuğu basılan kartları takip et
  Set<String> _expandedCards = {}; // Genişletilmiş kartları takip et
  
  // Nazar boncuğu animasyonu için
  late AnimationController _nazarAnimationController;
  late Animation<double> _nazarScaleAnimation;
  late Animation<double> _nazarOpacityAnimation;
  bool _showNazarOverlay = false;

  @override
  void initState() {
    super.initState();
    _localProposals = List.from(widget.proposals);
    
    // Nazar boncuğu animasyon controller'ını başlat
    _nazarAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _nazarScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _nazarAnimationController,
      curve: Curves.elasticOut,
    ));
    
    _nazarOpacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _nazarAnimationController,
      curve: Interval(0.7, 1.0, curve: Curves.easeOut),
    ));
  }

  @override
  void didUpdateWidget(covariant SuggestedCandidatesSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.proposals != widget.proposals) {
      _localProposals = List.from(widget.proposals);
    }
  }

  @override
  void dispose() {
    _nazarAnimationController.dispose();
    super.dispose();
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

  void _handleNazarBoncugu(MatchProposal proposal) async {
    setState(() {
      _nazerBoncuguPressed.add(proposal.id);
      _showNazarOverlay = true;
    });
    
    // Backend'e nazar boncuğu gönder
    try {
      await MatchService().sendNazarBoncugu(
        matchId: proposal.id, // MatchProposal ID'sini kullan (şimdilik)
        fromUserId: widget.currentUser.id,
        fromUserName: widget.currentUser.fullName,
      );
    } catch (e) {
      print('Nazar boncuğu gönderilemedi: $e');
    }
    
    // Kocaman nazar boncuğu animasyonunu başlat
    _nazarAnimationController.forward().then((_) {
      setState(() {
        _showNazarOverlay = false;
      });
      _nazarAnimationController.reset();
      
      // Animasyon bittikten sonra kartı kabul et (sağa kaydır)
      _handleAccept(proposal);
    });
    
    // Bildirim göster
    Future.delayed(Duration(milliseconds: 500), () {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Text('🧿'),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text(
                    'Nazar boncuğu gönderildi! Kötü gözlerden korunuyor 🙏',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.blue[700],
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.selectedSelector == null) {
      return _buildNoSelectorSelected();
    }

    if (_localProposals.isEmpty) {
      return _buildNoSuggestions();
    }

    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(),
            SizedBox(height: 1.h),
            SizedBox(
              height: 70.h,
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
        ),
        // Kocaman nazar boncuğu overlay
        if (_showNazarOverlay)
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                // Overlay'e tıklandığında hiçbir şey yapma (geçişi engelle)
              },
              child: AnimatedBuilder(
                animation: _nazarAnimationController,
                builder: (context, child) {
                  return Container(
                    color: Colors.black.withValues(alpha: 0.3),
                    child: Center(
                      child: Transform.scale(
                        scale: _nazarScaleAnimation.value,
                        child: Opacity(
                          opacity: _nazarOpacityAnimation.value,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue.withValues(alpha: 0.5),
                                  blurRadius: 30,
                                  spreadRadius: 10,
                                ),
                              ],
                            ),
                            padding: EdgeInsets.all(8.w),
                            child: Text(
                              '🧿',
                              style: TextStyle(fontSize: 40.w), // Kocaman emoji
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
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
                style: TextStyle(color: Colors.grey[600], fontSize: 8.sp),
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
          // Nazar boncuğu butonu (sağ üst köşe)
          Positioned(
            top: 4.w,
            right: 4.w,
            child: Container(
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
                onPressed: () => _handleNazarBoncugu(proposal),
                backgroundColor: Colors.blue[700],
                elevation: 0,
                child: Icon(
                  Icons.remove_red_eye,
                  color: Colors.white,
                  size: 5.w,
                ),
              ),
            ),
          ),
          // About dropdown button - top left corner  
          if (otherCandidateBio != null && otherCandidateBio!.isNotEmpty)
            Positioned(
              top: 4.w,
              left: 4.w,
              child: GestureDetector(
                onTap: () => _showAboutDialog(otherCandidateName, otherCandidateBio!),
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
          // Profile information - centered name with details below
          Positioned(
            top: 45.h, // Biraz daha aşağı taşındı
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
                      otherCandidateName.split(' ').first, // Only first name
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32.sp, // Büyük font size
                        fontWeight: FontWeight.w700, // Extra bold
                        letterSpacing: -0.5,
                      ),
                    ),
                    SizedBox(width: 2.w),
                    // Yaş bilgisi varsa göster (simüle edilmiş)
                    Text(
                      '${20 + (proposal.id.hashCode % 15)}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7), // Daha transparan
                        fontSize: 32.sp, // Same size as name
                        fontWeight: FontWeight.w400, // Regular weight
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                // Location and Profession - centered and smaller
                SizedBox(height: 1.h),
                Column(
                  children: [
                    // Lokasyon (simüle edilmiş)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.location_on,
                          color: Colors.white.withValues(alpha: 0.7),
                          size: 16,
                        ),
                        SizedBox(width: 1.w),
                        Text(
                          _getSimulatedLocation(proposal.id),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w400,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                    SizedBox(height: 0.2.h),
                    // Meslek (simüle edilmiş)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.work,
                          color: Colors.white.withValues(alpha: 0.7),
                          size: 16,
                        ),
                        SizedBox(width: 1.w),
                        Text(
                          _getSimulatedProfession(proposal.id),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w400,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
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
                  Wrap(
                    spacing: 1.w,
                    runSpacing: 0.5.h,
                    children: _getSimulatedHobbies(proposal.id).take(5).map((interest) {
                      return Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 1.5.w,
                          vertical: 0.3.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          interest,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 8.sp,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
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
            onPressed: () => _handleNazarBoncugu(proposal),
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

  Widget _buildExpandedDetails(MatchProposal proposal, bool isDirectCandidate) {
    // Hangi adayın bilgilerini göstereceğimizi belirle
    final candidateData = isDirectCandidate 
        ? {
            'name': proposal.targetCandidateName,
            'bio': proposal.targetCandidateBio,
            'imageUrl': proposal.targetCandidateImageUrl,
          }
        : {
            'name': proposal.candidateName,
            'bio': proposal.candidateBio,
            'imageUrl': proposal.candidateImageUrl,
          };

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(3.w),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '👤 Aday Hakkında',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 1.h),
          
          // Aday temel bilgileri
          _buildDetailRow('👨‍💼 İsim:', candidateData['name'] ?? 'Bilinmeyen'),
          
          // Yaş bilgisi (şimdilik simüle edilmiş)
          _buildDetailRow('🎂 Yaş:', '${20 + (proposal.id.hashCode % 15)} yaşında'),
          
          // Lokasyon bilgisi (şimdilik simüle edilmiş)
          _buildDetailRow('📍 Konum:', _getSimulatedLocation(proposal.id)),
          
          // Meslek bilgisi (şimdilik simüle edilmiş)
          _buildDetailRow('💼 Meslek:', _getSimulatedProfession(proposal.id)),
          
          // Önerilen tarafından
          _buildDetailRow('💝 Önerilen:', proposal.selectorName ?? 'Bilinmeyen'),
          
          // Oluşturma tarihi
          _buildDetailRow('📅 Tarih:', _formatDate(proposal.createdAt)),
          
          // Bio detaylı
          if (candidateData['bio'] != null && candidateData['bio']!.isNotEmpty)
            _buildDetailRow('📝 Hakkında:', candidateData['bio']!),
          
          // Hobiler (şimdilik simüle edilmiş)
          _buildHobbiesRow(_getSimulatedHobbies(proposal.id)),
          
          // Durum bilgisi
          _buildDetailRow('📊 Durum:', proposal.isPending ? '⏳ Bekliyor' : '✅ İşlendi'),
          
          // Eşleşme türü
          _buildDetailRow('💕 Tür:', isDirectCandidate ? 'Size önerilen' : 'Karşılıklı eşleşme'),
          
          // Nazar durumu
          if (proposal.nazarFromUserName != null)
            _buildDetailRow('🧿 Nazar:', '${proposal.nazarFromUserName} tarafından korunuyor'),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.2.h),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 10.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: 10.sp,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHobbiesRow(List<String> hobbies) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.5.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🎯 Hobiler:',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 10.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 0.5.h),
          Wrap(
            spacing: 1.w,
            runSpacing: 0.5.h,
            children: hobbies.map((hobby) {
              return Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.3.h),
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.primaryColor.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(3.w),
                ),
                child: Text(
                  hobby,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  String _getSimulatedLocation(String id) {
    final locations = ['İstanbul', 'Ankara', 'İzmir', 'Antalya', 'Bursa', 'Adana', 'Gaziantep'];
    return locations[id.hashCode % locations.length];
  }

  String _getSimulatedProfession(String id) {
    final professions = ['Mühendis', 'Doktor', 'Öğretmen', 'Avukat', 'Mimar', 'Hemşire', 'Pazarlama Uzmanı', 'Grafik Tasarımcı'];
    return professions[id.hashCode % professions.length];
  }

  List<String> _getSimulatedHobbies(String id) {
    final allHobbies = ['Kitap okuma', 'Sinema', 'Spor', 'Müzik', 'Seyahat', 'Yemek yapma', 'Resim', 'Dans', 'Fotoğrafçılık', 'Bahçıvanlık'];
    final hobbyCount = 2 + (id.hashCode % 4); // 2-5 hobi
    final startIndex = id.hashCode % (allHobbies.length - hobbyCount);
    return allHobbies.sublist(startIndex, startIndex + hobbyCount);
  }

  void _showAboutDialog(String candidateName, String bio) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          '$candidateName Hakkında',
          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Container(
          constraints: BoxConstraints(maxHeight: 40.h),
          child: SingleChildScrollView(
            child: Text(
              bio,
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
