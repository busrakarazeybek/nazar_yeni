import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../models/match_proposal.dart';
import '../../../providers/auth_provider.dart';

class DecisionButtonsWidget extends StatelessWidget {
  final MatchProposal proposal;
  final bool isProcessing;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback onThinkAboutIt;

  const DecisionButtonsWidget({
    super.key,
    required this.proposal,
    required this.isProcessing,
    required this.onAccept,
    required this.onReject,
    required this.onThinkAboutIt,
  });

  @override
  Widget build(BuildContext context) {
    final currentUserId = AuthProvider().currentUser?.id;
    final canRespond = currentUserId != null &&
        (proposal.candidate1Id == currentUserId ||
            proposal.candidate2Id == currentUserId);

    // Check if already responded
    final hasResponded = !canRespond &&
        currentUserId != null &&
        (proposal.candidate1Id == currentUserId ||
            proposal.candidate2Id == currentUserId);

    String statusMessage = '';
    if (hasResponded) {
      final userStatus =
          'Kabul Edildi'; // Replace with actual logic to get user status
      if (userStatus == 'Kabul Edildi') {
        statusMessage = 'Kabul ettiniz. Karşı tarafın yanıtı bekleniyor...';
      } else if (userStatus == 'Reddedildi') {
        statusMessage = 'Bu öneriyi reddetmiştiniz.';
      }
    }

    return Container(
        decoration: BoxDecoration(color: Colors.white, boxShadow: [
          BoxShadow(
              color: Colors.black.withAlpha(26),
              blurRadius: 8,
              offset: const Offset(0, -2)),
        ]),
        child: SafeArea(
            top: false,
            child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  if (hasResponded) ...[
                    Container(
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                            color: Colors.blue[50],
                            border: Border.all(color: Colors.blue[200]!)),
                        child: Row(children: [
                          Icon(Icons.info_outline,
                              color: Colors.blue[600], size: 16.sp),
                          SizedBox(width: 8.w),
                          Expanded(
                              child: Text(statusMessage,
                                  style: TextStyle(
                                      fontSize: 14.sp,
                                      color: Colors.blue[700]))),
                        ])),
                    SizedBox(height: 16.h),
                  ],

                  if (canRespond && !isProcessing) ...[
                    // Main action buttons
                    Row(children: [
                      // Reject button
                      Expanded(
                          child: ElevatedButton(
                              onPressed: onReject,
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red[500],
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(vertical: 16.h),
                                  shape: RoundedRectangleBorder(),
                                  elevation: 0),
                              child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.close, size: 20.sp),
                                    SizedBox(width: 8.w),
                                    Text('Reddet',
                                        style: TextStyle(
                                            fontSize: 16.sp,
                                            fontWeight: FontWeight.w600)),
                                  ]))),

                      SizedBox(width: 12.w),

                      // Accept button
                      Expanded(
                          child: ElevatedButton(
                              onPressed: onAccept,
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green[500],
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(vertical: 16.h),
                                  shape: RoundedRectangleBorder(),
                                  elevation: 0),
                              child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.favorite, size: 20.sp),
                                    SizedBox(width: 8.w),
                                    Text('Kabul Et',
                                        style: TextStyle(
                                            fontSize: 16.sp,
                                            fontWeight: FontWeight.w600)),
                                  ]))),
                    ]),

                    SizedBox(height: 12.h),

                    // Think about it button
                    SizedBox(
                        width: double.infinity,
                        child: TextButton(
                            onPressed: onThinkAboutIt,
                            style: TextButton.styleFrom(
                                foregroundColor: Colors.grey[600],
                                padding: EdgeInsets.symmetric(vertical: 12.h),
                                shape: RoundedRectangleBorder(
                                    side:
                                        BorderSide(color: Colors.grey[300]!))),
                            child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.access_time, size: 16.sp),
                                  SizedBox(width: 8.w),
                                  Text('Düşünmek İstiyorum',
                                      style: TextStyle(
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.w500)),
                                ]))),
                  ] else if (isProcessing) ...[
                    // Loading state
                    Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                  width: 20.w,
                                  height: 20.h,
                                  child: const CircularProgressIndicator(
                                      strokeWidth: 2)),
                              SizedBox(width: 12.w),
                              Text('İşleniyor...',
                                  style: TextStyle(
                                      fontSize: 16.sp,
                                      color: Colors.grey[600])),
                            ])),
                  ] else ...[
                    // Already responded - show close button
                    SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.purple,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(vertical: 16.h),
                                shape: RoundedRectangleBorder(),
                                elevation: 0),
                            child: Text('Kapat',
                                style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w600)))),
                  ],

                  // Cultural context note
                  SizedBox(height: 12.h),
                  Container(
                      padding: EdgeInsets.all(8.w),
                      child: Text(
                          'Bu geleneksel görücülük sistemidir. Kararınızı dikkatli değerlendirin.',
                          style: TextStyle(
                              fontSize: 11.sp,
                              color: Colors.grey[500],
                              fontStyle: FontStyle.italic),
                          textAlign: TextAlign.center)),
                ]))));
  }
}
