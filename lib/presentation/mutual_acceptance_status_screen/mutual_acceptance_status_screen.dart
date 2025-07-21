import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_export.dart';
import '../../models/match_proposal.dart';
import './widgets/action_button_widget.dart';
import './widgets/candidate_status_card_widget.dart';
import './widgets/celebration_overlay_widget.dart';
import './widgets/progress_timeline_widget.dart';
import './widgets/status_indicator_widget.dart';

class MutualAcceptanceStatusScreen extends StatefulWidget {
  final String proposalId;

  const MutualAcceptanceStatusScreen({
    super.key,
    required this.proposalId,
  });

  @override
  State<MutualAcceptanceStatusScreen> createState() =>
      _MutualAcceptanceStatusScreenState();
}

class _MutualAcceptanceStatusScreenState
    extends State<MutualAcceptanceStatusScreen> with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _celebrationController;
  late Animation<double> _progressAnimation;

  MatchProposal? _proposal;
  bool _isLoading = true;
  String? _error;
  bool _showCelebration = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadProposal();
  }

  void _initializeAnimations() {
    _progressController = AnimationController(
        duration: const Duration(milliseconds: 1500), vsync: this);

    _celebrationController = AnimationController(
        duration: const Duration(milliseconds: 2000), vsync: this);

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
            parent: _progressController, curve: Curves.easeInOutCubic));
  }

  Future<void> _loadProposal() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // For now, create a mock proposal since we need to update the service
      // This should be replaced with actual service call
      final mockProposal = MatchProposal(
          id: widget.proposalId,
          selectorId: 'selector_1',
          candidateId: 'candidate_1',
          targetCandidateId: 'candidate_2',
          status: AcceptanceStatus.pending,
          targetStatus: AcceptanceStatus.pending,
          statusEnum: MatchProposalStatus.pending,
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
          updatedAt: DateTime.now().subtract(const Duration(minutes: 30)),
          estimatedResponseTime: DateTime.now().add(const Duration(hours: 22)),
          selectorName: 'Ahmet Seçici',
          selectorImageUrl:
              'https://images.pexels.com/photos/2379004/pexels-photo-2379004.jpeg');

      setState(() {
        _proposal = mockProposal;
        _isLoading = false;
      });

      // Animate progress
      _progressController.animateTo(_proposal!.progressPercentage);

      // Show celebration if match is complete
      if (_proposal!.isCompleted && !_showCelebration) {
        _showCelebrationAfterDelay();
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _showCelebrationAfterDelay() {
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() => _showCelebration = true);
        _celebrationController.forward();

        // Haptic feedback
        HapticFeedback.lightImpact();
      }
    });
  }

  Future<void> _refreshStatus() async {
    await _loadProposal();
  }

  void _startChat() {
    if (_proposal?.canStartChat == true) {
      Navigator.pushNamed(context, AppRoutes.chatScreen, arguments: {
        'conversationId': _proposal!.id,
        'partnerName': _getPartnerName(),
        'partnerImageUrl': _getPartnerImageUrl(),
      });
    }
  }

  String _getPartnerName() {
    final currentUserId =
        'mock_user_id'; // Replace AuthProvider.getCurrentUserId()
    if (currentUserId == _proposal?.candidate1Id) {
      return _proposal?.candidate2Name ?? 'Eşleşen Kişi';
    } else {
      return _proposal?.candidate1Name ?? 'Eşleşen Kişi';
    }
  }

  String? _getPartnerImageUrl() {
    final currentUserId =
        'mock_user_id'; // Replace AuthProvider.getCurrentUserId()
    if (currentUserId == _proposal?.candidate1Id) {
      return _proposal?.candidate2ImageUrl;
    } else {
      return _proposal?.candidate1ImageUrl;
    }
  }

  void _withdrawMatch() {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
                title: const Text('Eşleşmeyi Geri Çek'),
                content: const Text(
                    'Bu eşleşme önerisini geri çekmek istediğinizden emin misiniz? Bu işlem geri alınamaz.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('İptal')),
                  ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pop(context);
                        // Add withdrawal logic here
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.errorColor),
                      child: const Text('Geri Çek')),
                ]));
  }

  @override
  void dispose() {
    _progressController.dispose();
    _celebrationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
            title: const Text('Eşleşme Durumu'),
            backgroundColor: theme.scaffoldBackgroundColor,
            elevation: 0,
            actions: [
              IconButton(
                  icon: const Icon(Icons.refresh), onPressed: _refreshStatus),
            ]),
        body: Stack(children: [
          _buildMainContent(theme),
          if (_showCelebration && _proposal?.isCompleted == true)
            CelebrationOverlayWidget(
                controller: _celebrationController,
                onComplete: () => setState(() => _showCelebration = false)),
        ]));
  }

  Widget _buildMainContent(ThemeData theme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.error_outline, size: 64, color: AppTheme.errorColor),
        const SizedBox(height: 16),
        Text('Bir hata oluştu', style: theme.textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(_error!,
            style: theme.textTheme.bodyMedium?.copyWith(),
            textAlign: TextAlign.center),
        const SizedBox(height: 24),
        ElevatedButton(
            onPressed: _loadProposal, child: const Text('Tekrar Dene')),
      ]));
    }

    if (_proposal == null) {
      return const Center(child: Text('Eşleşme bulunamadı'));
    }

    return RefreshIndicator(
        onRefresh: _refreshStatus,
        child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Progress Timeline
                  ProgressTimelineWidget(
                      proposal: _proposal!,
                      progressAnimation: _progressAnimation),

                  const SizedBox(height: 24),

                  // Status Indicator
                  StatusIndicatorWidget(proposal: _proposal!),

                  const SizedBox(height: 24),

                  // Candidate Status Cards
                  CandidateStatusCardWidget(
                      proposal: _proposal!, isCandidate1: true),

                  const SizedBox(height: 16),

                  CandidateStatusCardWidget(
                      proposal: _proposal!, isCandidate1: false),

                  const SizedBox(height: 32),

                  // Action Buttons
                  ActionButtonWidget(
                      proposal: _proposal!,
                      onStartChat: _startChat,
                      onWithdraw: _withdrawMatch),

                  const SizedBox(height: 24),

                  // Time Remaining (if applicable)
                  if (_proposal!.timeRemaining != null)
                    _buildTimeRemaining(theme),
                ])));
  }

  Widget _buildTimeRemaining(ThemeData theme) {
    final timeRemaining = _proposal!.timeRemaining!;
    final hours = timeRemaining.inHours;
    final minutes = timeRemaining.inMinutes % 60;

    return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: AppTheme.warningColor.withAlpha(26),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: AppTheme.warningColor.withAlpha(77), width: 1)),
        child: Row(children: [
          const Icon(Icons.schedule, color: AppTheme.warningColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text('Tahmini Yanıt Süresi',
                    style: theme.textTheme.labelMedium?.copyWith(
                        color: AppTheme.warningColor,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text('${hours}s ${minutes}dk kaldı',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w500)),
              ])),
        ]));
  }
}
