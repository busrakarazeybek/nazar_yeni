import 'package:flutter/material.dart';

import '../../../core/app_export.dart';
import '../../../models/match_proposal.dart';
import '../../../theme/app_theme.dart';

class ProgressTimelineWidget extends StatelessWidget {
  final MatchProposal proposal;
  final Animation<double> progressAnimation;

  const ProgressTimelineWidget({
    super.key,
    required this.proposal,
    required this.progressAnimation,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: theme.shadowColor.withAlpha(26),
                  offset: const Offset(0, 2),
                  blurRadius: 8),
            ]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Eşleşme Süreci',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w600)),

          const SizedBox(height: 20),

          // Progress Bar
          AnimatedBuilder(
              animation: progressAnimation,
              builder: (context, child) {
                return Column(children: [
                  LinearProgressIndicator(
                      value:
                          progressAnimation.value * proposal.progressPercentage,
                      valueColor: AlwaysStoppedAnimation<Color>(
                          proposal.isCompleted
                              ? AppTheme.successColor
                              : AppTheme.primaryLight),
                      minHeight: 6),

                  const SizedBox(height: 16),

                  // Timeline Steps
                  Row(children: [
                    _buildTimelineStep(context,
                        icon: Icons.send,
                        title: 'Öneri Gönderildi',
                        isCompleted: true,
                        isActive: proposal.finalStatus ==
                            MatchProposalStatus.pending),
                    Expanded(child: _buildTimelineLine(context, true)),
                    _buildTimelineStep(context,
                        icon: Icons.person_add,
                        title: 'İlk Onay',
                        isCompleted: proposal.finalStatus ==
                                MatchProposalStatus.candidate1Accepted ||
                            proposal.finalStatus ==
                                MatchProposalStatus.candidate2Accepted ||
                            proposal.finalStatus ==
                                MatchProposalStatus.bothAccepted,
                        isActive: proposal.finalStatus ==
                                MatchProposalStatus.candidate1Accepted ||
                            proposal.finalStatus ==
                                MatchProposalStatus.candidate2Accepted),
                    Expanded(
                        child: _buildTimelineLine(
                            context,
                            proposal.finalStatus ==
                                    MatchProposalStatus.candidate1Accepted ||
                                proposal.finalStatus ==
                                    MatchProposalStatus.candidate2Accepted ||
                                proposal.finalStatus ==
                                    MatchProposalStatus.bothAccepted)),
                    _buildTimelineStep(context,
                        icon: Icons.favorite,
                        title: 'Eşleşme',
                        isCompleted: proposal.finalStatus ==
                            MatchProposalStatus.bothAccepted,
                        isActive: proposal.finalStatus ==
                            MatchProposalStatus.bothAccepted),
                  ]),
                ]);
              }),

          const SizedBox(height: 16),

          // Status Description
          Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: _getStatusColor().withAlpha(26),
                  borderRadius: BorderRadius.circular(8)),
              child: Row(children: [
                Icon(_getStatusIcon(), color: _getStatusColor(), size: 20),
                const SizedBox(width: 12),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(proposal.statusDescription,
                          style: theme.textTheme.labelLarge?.copyWith(
                              color: _getStatusColor(),
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(proposal.nextStepDescription,
                          style: theme.textTheme.bodySmall?.copyWith()),
                    ])),
              ])),
        ]));
  }

  Widget _buildTimelineStep(
    BuildContext context, {
    required IconData icon,
    required String title,
    required bool isCompleted,
    required bool isActive,
  }) {
    final theme = Theme.of(context);

    Color stepColor;
    if (isCompleted) {
      stepColor = AppTheme.successColor;
    } else if (isActive) {
      stepColor = AppTheme.primaryLight;
    } else {
      stepColor = theme.dividerColor;
    }

    return Column(children: [
      Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
              color: isCompleted || isActive ? stepColor : theme.cardColor,
              border: Border.all(color: stepColor, width: 2),
              shape: BoxShape.circle),
          child: Icon(isCompleted ? Icons.check : icon,
              color: isCompleted || isActive ? Colors.white : stepColor,
              size: 20)),
      const SizedBox(height: 8),
      SizedBox(
          width: 60,
          child: Text(title,
              style: theme.textTheme.labelSmall?.copyWith(
                  color: isCompleted || isActive
                      ? theme.textTheme.bodyLarge?.color
                      : theme.textTheme.bodySmall?.color,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis)),
    ]);
  }

  Widget _buildTimelineLine(BuildContext context, bool isCompleted) {
    final theme = Theme.of(context);

    return Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 32),
        decoration: BoxDecoration(
            color: isCompleted ? AppTheme.successColor : theme.dividerColor,
            borderRadius: BorderRadius.circular(1)));
  }

  Color _getStatusColor() {
    switch (proposal.finalStatus) {
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

  IconData _getStatusIcon() {
    switch (proposal.finalStatus) {
      case MatchProposalStatus.pending:
        return Icons.schedule;
      case MatchProposalStatus.candidate1Accepted:
      case MatchProposalStatus.candidate2Accepted:
      case MatchProposalStatus.candidateAccepted:
      case MatchProposalStatus.targetCandidateAccepted:
        return Icons.person_add;
      case MatchProposalStatus.bothAccepted:
        return Icons.celebration;
      case MatchProposalStatus.rejected:
        return Icons.close;
    }
  }
}
