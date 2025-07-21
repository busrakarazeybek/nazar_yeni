import 'package:flutter/material.dart';

import '../../../core/app_export.dart';
import '../../../models/match_proposal.dart';
import '../../../theme/app_theme.dart';

class CandidateStatusCardWidget extends StatelessWidget {
  final MatchProposal proposal;
  final bool isCandidate1;

  const CandidateStatusCardWidget({
    super.key,
    required this.proposal,
    required this.isCandidate1,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final candidateName =
        isCandidate1 ? proposal.candidate1Name : proposal.candidate2Name;
    final candidateImageUrl = isCandidate1
        ? proposal.candidate1ImageUrl
        : proposal.candidate2ImageUrl;
    final status = isCandidate1 ? proposal.status1 : proposal.status2;
    final timestamp = _getTimestamp();

    return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: _getStatusColor(status).withAlpha(77), width: 1),
            boxShadow: [
              BoxShadow(
                  color: theme.shadowColor.withAlpha(13),
                  offset: const Offset(0, 1),
                  blurRadius: 4),
            ]),
        child: Row(children: [
          // Profile Image
          Stack(children: [
            CircleAvatar(
                radius: 28,
                backgroundImage: candidateImageUrl != null
                    ? NetworkImage(candidateImageUrl)
                    : null,
                child: candidateImageUrl == null
                    ? Icon(Icons.person, size: 32)
                    : null),

            // Status Badge
            Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                        color: _getStatusColor(status),
                        border: Border.all(color: theme.cardColor, width: 2),
                        shape: BoxShape.circle),
                    child: Icon(_getStatusIcon(status),
                        size: 12, color: Colors.white))),
          ]),

          const SizedBox(width: 16),

          // Candidate Info
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(candidateName ?? 'Aday',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Row(children: [
                  Icon(_getStatusIcon(status),
                      size: 16, color: _getStatusColor(status)),
                  const SizedBox(width: 6),
                  Expanded(
                      child: Text(_getStatusText(status),
                          style: theme.textTheme.bodyMedium?.copyWith(
                              color: _getStatusColor(status),
                              fontWeight: FontWeight.w500))),
                ]),
                if (timestamp != null) ...[
                  const SizedBox(height: 4),
                  Text(timestamp, style: theme.textTheme.bodySmall?.copyWith()),
                ],
              ])),

          // Action Indicator
          if (status == AcceptanceStatus.pending)
            Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: AppTheme.warningColor.withAlpha(26),
                    borderRadius: BorderRadius.circular(6)),
                child: Text('Bekliyor',
                    style: theme.textTheme.labelSmall?.copyWith(
                        color: AppTheme.warningColor,
                        fontWeight: FontWeight.w600))),
        ]));
  }

  Color _getStatusColor(AcceptanceStatus status) {
    switch (status) {
      case AcceptanceStatus.pending:
        return AppTheme.warningColor;
      case AcceptanceStatus.accepted:
        return AppTheme.successColor;
      case AcceptanceStatus.rejected:
        return AppTheme.errorColor;
    }
  }

  IconData _getStatusIcon(AcceptanceStatus status) {
    switch (status) {
      case AcceptanceStatus.pending:
        return Icons.schedule;
      case AcceptanceStatus.accepted:
        return Icons.check_circle;
      case AcceptanceStatus.rejected:
        return Icons.cancel;
    }
  }

  String _getStatusText(AcceptanceStatus status) {
    switch (status) {
      case AcceptanceStatus.pending:
        return 'Yanıt bekleniyor';
      case AcceptanceStatus.accepted:
        return 'Kabul etti';
      case AcceptanceStatus.rejected:
        return 'Reddetti';
    }
  }

  String? _getTimestamp() {
    if (proposal.updatedAt != null) {
      final now = DateTime.now();
      final difference = now.difference(proposal.updatedAt!);

      if (difference.inMinutes < 1) {
        return 'Şimdi';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes} dk önce';
      } else if (difference.inHours < 24) {
        return '${difference.inHours} saat önce';
      } else {
        return '${difference.inDays} gün önce';
      }
    }
    return null;
  }
}
