import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../models/match_proposal.dart';

class ProposalCardWidget extends StatelessWidget {
  final MatchProposal proposal;
  final VoidCallback? onTap;
  final VoidCallback? onWithdraw;

  const ProposalCardWidget({
    super.key,
    required this.proposal,
    this.onTap,
    this.onWithdraw,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
        margin: EdgeInsets.only(bottom: 2.h),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withAlpha(13),
                  blurRadius: 10,
                  offset: Offset(0, 2)),
            ]),
        child: Material(
            color: Colors.transparent,
            child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                    padding: EdgeInsets.all(4.w),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(),
                          SizedBox(height: 2.h),
                          _buildCandidatesPair(),
                          SizedBox(height: 2.h),
                          _buildStatusRow(),
                          if (onWithdraw != null) ...[
                            SizedBox(height: 2.h),
                            _buildActionButtons(),
                          ],
                        ])))));
  }

  Widget _buildHeader() {
    return Row(children: [
      Container(
          padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
          decoration: BoxDecoration(
              color: _getStatusColor().withAlpha(26),
              borderRadius: BorderRadius.circular(20)),
          child: Text(proposal.statusDescription,
              style: TextStyle(
                  color: _getStatusColor(),
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w600))),
      Spacer(),
      Text(_formatDate(proposal.createdAt),
          style: TextStyle(color: Colors.grey[600], fontSize: 10.sp)),
    ]);
  }

  Widget _buildCandidatesPair() {
    return Row(children: [
      _buildCandidateInfo(
          name: proposal.candidate1Name ?? 'Aday 1',
          imageUrl: proposal.candidate1ImageUrl,
          isFirst: true),
      SizedBox(width: 4.w),
      Container(
          padding: EdgeInsets.all(2.w),
          decoration: BoxDecoration(
              color: AppTheme.lightTheme.primaryColor.withAlpha(26),
              shape: BoxShape.circle),
          child: CustomIconWidget(
              iconName: 'favorite',
              color: AppTheme.lightTheme.primaryColor,
              size: 16.w)),
      SizedBox(width: 4.w),
      _buildCandidateInfo(
          name: proposal.candidate2Name ?? 'Aday 2',
          imageUrl: proposal.candidate2ImageUrl,
          isFirst: false),
    ]);
  }

  Widget _buildCandidateInfo({
    required String name,
    String? imageUrl,
    required bool isFirst,
  }) {
    final status = isFirst ? proposal.status1 : proposal.status2;
    final statusColor = _getAcceptanceStatusColor(status);

    return Expanded(
        child: Column(children: [
      Stack(children: [
        CircleAvatar(
            radius: 25.w,
            backgroundColor: Colors.grey[200],
            child: imageUrl != null
                ? CustomImageWidget(
                    imageUrl: imageUrl,
                    height: 50.w,
                    width: 50.w,
                    fit: BoxFit.cover)
                : CustomIconWidget(
                    iconName: 'person', color: Colors.grey[400]!, size: 30.w)),
        Positioned(
            bottom: 0,
            right: 0,
            child: Container(
                padding: EdgeInsets.all(1.w),
                decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2)),
                child: CustomIconWidget(
                    iconName: _getAcceptanceStatusIcon(status),
                    color: Colors.white,
                    size: 12.w))),
      ]),
      SizedBox(height: 1.h),
      Text(name,
          style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis),
      Text(_getAcceptanceStatusText(status),
          style: TextStyle(
              fontSize: 10.sp, color: statusColor, fontWeight: FontWeight.w500),
          textAlign: TextAlign.center),
    ]));
  }

  Widget _buildStatusRow() {
    return Row(children: [
      Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Durum',
            style: TextStyle(fontSize: 10.sp, color: Colors.grey[600])),
        SizedBox(height: 0.5.h),
        Text(proposal.nextStepDescription,
            style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w500)),
      ])),
      SizedBox(width: 4.w),
      _buildProgressIndicator(),
    ]);
  }

  Widget _buildProgressIndicator() {
    return SizedBox(
        width: 20.w,
        height: 20.w,
        child: Stack(children: [
          CircularProgressIndicator(
              value: proposal.progressPercentage,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(_getStatusColor()),
              strokeWidth: 3),
          Center(
              child: Text('${(proposal.progressPercentage * 100).toInt()}%',
                  style: TextStyle(
                      fontSize: 9.sp,
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor()))),
        ]));
  }

  Widget _buildActionButtons() {
    return Row(children: [
      if (onWithdraw != null)
        Expanded(
            child: OutlinedButton.icon(
                onPressed: onWithdraw,
                icon: CustomIconWidget(
                    iconName: 'close', color: AppTheme.errorColor, size: 16.w),
                label: Text('Geri Çek',
                    style: TextStyle(color: AppTheme.errorColor)),
                style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppTheme.errorColor)))),
      if (onWithdraw != null) SizedBox(width: 4.w),
      Expanded(
          child: ElevatedButton.icon(
              onPressed: onTap,
              icon: CustomIconWidget(
                  iconName: 'visibility', color: Colors.white, size: 16.w),
              label: Text('Detaylar'))),
    ]);
  }

  Color _getStatusColor() {
    switch (proposal.finalStatus) {
      case MatchProposalStatus.pending:
        return Colors.orange;
      case MatchProposalStatus.candidate1Accepted:
      case MatchProposalStatus.candidate2Accepted:
      case MatchProposalStatus.candidateAccepted:
      case MatchProposalStatus.targetCandidateAccepted:
        return Colors.blue;
      case MatchProposalStatus.bothAccepted:
        return Colors.green;
      case MatchProposalStatus.rejected:
        return Colors.red;
    }
  }

  Color _getAcceptanceStatusColor(AcceptanceStatus status) {
    switch (status) {
      case AcceptanceStatus.accepted:
        return Colors.green;
      case AcceptanceStatus.rejected:
        return Colors.red;
      case AcceptanceStatus.pending:
        return Colors.orange;
    }
  }

  String _getAcceptanceStatusIcon(AcceptanceStatus status) {
    switch (status) {
      case AcceptanceStatus.accepted:
        return 'check';
      case AcceptanceStatus.rejected:
        return 'close';
      case AcceptanceStatus.pending:
        return 'schedule';
    }
  }

  String _getAcceptanceStatusText(AcceptanceStatus status) {
    switch (status) {
      case AcceptanceStatus.accepted:
        return 'Kabul Etti';
      case AcceptanceStatus.rejected:
        return 'Reddetti';
      case AcceptanceStatus.pending:
        return 'Bekliyor';
    }
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
