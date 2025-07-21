import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/app_export.dart';
import '../../../models/match_proposal.dart';
import '../../../widgets/custom_image_widget.dart';

class ProposalHeaderWidget extends StatelessWidget {
  final MatchProposal proposal;
  final VoidCallback onClose;

  const ProposalHeaderWidget({
    super.key,
    required this.proposal,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
              Colors.purple[700]!,
              Colors.purple[500]!,
            ])),
        child: SafeArea(
            child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Column(children: [
                  // Close button and title
                  Row(children: [
                    IconButton(
                        onPressed: onClose,
                        icon: const Icon(Icons.close, color: Colors.white)),
                    Expanded(
                        child: Text('Eşleşme Önerisi',
                            style: GoogleFonts.inter(
                                fontSize: 20.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.white),
                            textAlign: TextAlign.center)),
                    SizedBox(width: 48.w), // Balance the close button
                  ]),

                  SizedBox(height: 16.h),

                  // Selector info
                  Row(children: [
                    CircleAvatar(
                        backgroundColor: Colors.white,
                        child: ClipRRect(
                            child: proposal.selectorImageUrl != null
                                ? CustomImageWidget(
                                    imageUrl: proposal.selectorImageUrl,
                                    width: 40.w,
                                    height: 40.h,
                                    fit: BoxFit.cover)
                                : Icon(Icons.person,
                                    size: 20.sp, color: Colors.purple[300]))),
                    SizedBox(width: 12.w),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(
                              '${proposal.selectorName ?? "Bir seçici"} sizin için bir öneri gönderdi',
                              style: GoogleFonts.inter(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white)),
                          SizedBox(height: 2.h),
                          Text('Görücü geleneklerine uygun olarak',
                              style: GoogleFonts.inter(
                                  fontSize: 12.sp, color: Colors.white70)),
                        ])),
                  ]),

                  SizedBox(height: 16.h),

                  // Cultural context note
                  Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                          color: Colors.white.withAlpha(26),
                          border:
                              Border.all(color: Colors.white.withAlpha(77))),
                      child: Row(children: [
                        Icon(Icons.info_outline,
                            color: Colors.white70, size: 16.sp),
                        SizedBox(width: 8.w),
                        Expanded(
                            child: Text(
                                'Bu geleneksel görücülük sistemidir. Her iki tarafın da onayı gerekir.',
                                style: GoogleFonts.inter(
                                    fontSize: 12.sp, color: Colors.white70))),
                      ])),
                ]))));
  }
}
