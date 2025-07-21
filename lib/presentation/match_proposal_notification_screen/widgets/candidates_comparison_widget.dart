import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../models/match_proposal.dart';

class CandidatesComparisonWidget extends StatelessWidget {
  final MatchProposal proposal;

  const CandidatesComparisonWidget({
    super.key,
    required this.proposal,
  });

  @override
  Widget build(BuildContext context) {
    final currentUserId = AuthProvider().currentUser?.id;

    // Determine which candidate is the current user and which is the match
    final isCurrentUserCandidate1 = proposal.candidate1Id == currentUserId;
    final currentUserName = isCurrentUserCandidate1
        ? proposal.candidate1Name
        : proposal.candidate2Name;
    final currentUserImage = isCurrentUserCandidate1
        ? proposal.candidate1ImageUrl
        : proposal.candidate2ImageUrl;

    final matchName = isCurrentUserCandidate1
        ? proposal.candidate2Name
        : proposal.candidate1Name;
    final matchImage = isCurrentUserCandidate1
        ? proposal.candidate2ImageUrl
        : proposal.candidate1ImageUrl;

    return Card(
        elevation: 4,
        shape: RoundedRectangleBorder(),
        child: Padding(
            padding: EdgeInsets.all(16.w),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Önerilen Eşleşme',
                  style: GoogleFonts.inter(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87)),
              SizedBox(height: 16.h),

              Row(children: [
                // Current user profile
                Expanded(
                    child: _buildProfileCard(
                        name: currentUserName ?? 'Siz',
                        imageUrl: currentUserImage,
                        isCurrentUser: true)),

                // Heart connector
                Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: Column(children: [
                      Container(
                          padding: EdgeInsets.all(8.w),
                          decoration: BoxDecoration(
                              color: Colors.pink[50],
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.pink[200]!)),
                          child: Icon(Icons.favorite,
                              color: Colors.pink[400], size: 20.sp)),
                      SizedBox(height: 4.h),
                      Text('Eşleşme',
                          style: GoogleFonts.inter(
                              fontSize: 10.sp,
                              color: Colors.pink[600],
                              fontWeight: FontWeight.w500)),
                    ])),

                // Match profile
                Expanded(
                    child: _buildProfileCard(
                        name: matchName ?? 'Eşleşen Kişi',
                        imageUrl: matchImage,
                        isCurrentUser: false)),
              ]),

              SizedBox(height: 16.h),

              // Compatibility note
              Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                      color: Colors.green[50],
                      border: Border.all(color: Colors.green[200]!)),
                  child: Row(children: [
                    Icon(Icons.auto_awesome,
                        color: Colors.green[600], size: 16.sp),
                    SizedBox(width: 8.w),
                    Expanded(
                        child: Text(
                            'Seçici sizin için uygun bir eşleşme olduğunu düşünüyor',
                            style: GoogleFonts.inter(
                                fontSize: 12.sp, color: Colors.green[700]))),
                  ])),
            ])));
  }

  Widget _buildProfileCard({
    required String name,
    String? imageUrl,
    required bool isCurrentUser,
  }) {
    return Column(children: [
      Stack(children: [
        Container(
            width: 80.w,
            height: 80.h,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color:
                        isCurrentUser ? Colors.purple[300]! : Colors.blue[300]!,
                    width: 3)),
            child: ClipRRect(
                child: imageUrl != null
                    ? CustomImageWidget(imageUrl: imageUrl, fit: BoxFit.cover)
                    : Container(
                        color: Colors.grey[200],
                        child: Icon(Icons.person,
                            size: 40.sp, color: Colors.grey[400])))),
        if (isCurrentUser)
          Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                  padding: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(
                      color: Colors.purple,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2)),
                  child: Icon(Icons.star, color: Colors.white, size: 12.sp))),
      ]),
      SizedBox(height: 8.h),
      Text(name,
          style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: isCurrentUser ? Colors.purple[700] : Colors.blue[700]),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis),
      if (isCurrentUser) ...[
        SizedBox(height: 2.h),
        Text('(Siz)',
            style: GoogleFonts.inter(
                fontSize: 11.sp,
                color: Colors.purple[500],
                fontWeight: FontWeight.w500)),
      ],
    ]);
  }
}
