import 'package:flutter/material.dart';

import '../../../core/app_export.dart';
import '../../../models/match_proposal.dart';
import '../../../theme/app_theme.dart';

class StatusIndicatorWidget extends StatefulWidget {
  final MatchProposal proposal;

  const StatusIndicatorWidget({
    super.key,
    required this.proposal,
  });

  @override
  State<StatusIndicatorWidget> createState() => _StatusIndicatorWidgetState();
}

class _StatusIndicatorWidgetState extends State<StatusIndicatorWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initializePulseAnimation();
  }

  void _initializePulseAnimation() {
    _pulseController =
        AnimationController(duration: const Duration(seconds: 2), vsync: this);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
        CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

    // Start pulsing animation for pending status
    if (widget.proposal.isPending) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: _getBackgroundColor().withAlpha(26),
            borderRadius: BorderRadius.circular(16),
            border:
                Border.all(color: _getStatusColor().withAlpha(77), width: 1)),
        child: Column(children: [
          // Main Status Icon
          AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                    scale:
                        widget.proposal.isPending ? _pulseAnimation.value : 1.0,
                    child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                            color: _getStatusColor(),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                  color: _getStatusColor().withAlpha(51),
                                  offset: const Offset(0, 4),
                                  blurRadius: 12),
                            ]),
                        child: Icon(_getMainIcon(),
                            size: 40, color: Colors.white)));
              }),

          const SizedBox(height: 16),

          // Status Title
          Text(_getStatusTitle(),
              style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700, color: _getStatusColor()),
              textAlign: TextAlign.center),

          const SizedBox(height: 8),

          // Status Description
          Text(_getDetailedDescription(),
              style: theme.textTheme.bodyMedium?.copyWith(),
              textAlign: TextAlign.center),

          const SizedBox(height: 16),

          // Progress Dots
          _buildProgressDots(theme),

          // Waiting Information
          if (widget.proposal.waitingForCandidateName != null) ...[
            const SizedBox(height: 16),
            _buildWaitingInfo(theme),
          ],
        ]));
  }

  Widget _buildProgressDots(ThemeData theme) {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      _buildProgressDot(true, theme), // Proposal sent
      const SizedBox(width: 8),
      _buildProgressDot(_hasFirstAcceptance(), theme), // First acceptance
      const SizedBox(width: 8),
      _buildProgressDot(widget.proposal.isCompleted, theme), // Both accepted
    ]);
  }

  Widget _buildProgressDot(bool isActive, ThemeData theme) {
    return Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(shape: BoxShape.circle));
  }

  Widget _buildWaitingInfo(ThemeData theme) {
    return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(width: 1)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.schedule, size: 16),
          const SizedBox(width: 8),
          Text('Beklenen: ${widget.proposal.waitingForCandidateName}',
              style: theme.textTheme.bodySmall
                  ?.copyWith(fontWeight: FontWeight.w500)),
        ]));
  }

  bool _hasFirstAcceptance() {
    return widget.proposal.status1 == AcceptanceStatus.accepted ||
        widget.proposal.status2 == AcceptanceStatus.accepted;
  }

  Color _getStatusColor() {
    switch (widget.proposal.finalStatus) {
      case MatchProposalStatus.pending:
        return AppTheme.warningColor;
      case MatchProposalStatus.candidate1Accepted:
      case MatchProposalStatus.candidate2Accepted:
      case MatchProposalStatus.candidateAccepted:
      case MatchProposalStatus.targetCandidateAccepted:
        return AppTheme.primaryLight;
      case MatchProposalStatus.bothAccepted:
        return AppTheme.successColor;
      case MatchProposalStatus.rejected:
        return AppTheme.errorColor;
    }
  }

  Color _getBackgroundColor() {
    return _getStatusColor();
  }

  IconData _getMainIcon() {
    switch (widget.proposal.finalStatus) {
      case MatchProposalStatus.pending:
        return Icons.hourglass_empty;
      case MatchProposalStatus.candidate1Accepted:
      case MatchProposalStatus.candidate2Accepted:
      case MatchProposalStatus.candidateAccepted:
      case MatchProposalStatus.targetCandidateAccepted:
        return Icons.people;
      case MatchProposalStatus.bothAccepted:
        return Icons.celebration;
      case MatchProposalStatus.rejected:
        return Icons.close;
    }
  }

  String _getStatusTitle() {
    switch (widget.proposal.finalStatus) {
      case MatchProposalStatus.pending:
        return 'Yanıt Bekleniyor';
      case MatchProposalStatus.candidate1Accepted:
      case MatchProposalStatus.candidate2Accepted:
      case MatchProposalStatus.candidateAccepted:
      case MatchProposalStatus.targetCandidateAccepted:
        return 'Yarı Kabul';
      case MatchProposalStatus.bothAccepted:
        return 'Eşleşme Tamamlandı!';
      case MatchProposalStatus.rejected:
        return 'Reddedildi';
    }
  }

  String _getDetailedDescription() {
    switch (widget.proposal.finalStatus) {
      case MatchProposalStatus.pending:
        return 'Her iki adayın da yanıtı bekleniyor. Genellikle 24-48 saat içinde yanıt alınır.';
      case MatchProposalStatus.candidate1Accepted:
      case MatchProposalStatus.candidate2Accepted:
      case MatchProposalStatus.candidateAccepted:
      case MatchProposalStatus.targetCandidateAccepted:
        return 'Bir aday kabul etti! Diğer adayın yanıtı bekleniyor.';
      case MatchProposalStatus.bothAccepted:
        return 'Tebrikler! Her iki aday da eşleşmeyi kabul etti. Artık sohbet başlatabilirsiniz.';
      case MatchProposalStatus.rejected:
        return 'Maalesef eşleşme reddedildi. Başka öneriler için arama yapmaya devam edebilirsiniz.';
    }
  }
}
