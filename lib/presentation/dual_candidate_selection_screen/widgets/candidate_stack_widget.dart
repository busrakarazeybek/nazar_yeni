import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class CandidateStackWidget extends StatefulWidget {
  final List<UserProfile> candidates;
  final UserProfile? selectedCandidate;
  final Function(UserProfile) onCandidateSelected;

  const CandidateStackWidget({
    super.key,
    required this.candidates,
    required this.selectedCandidate,
    required this.onCandidateSelected,
  });

  @override
  State<CandidateStackWidget> createState() => _CandidateStackWidgetState();
}

class _CandidateStackWidgetState extends State<CandidateStackWidget> {
  int _currentIndex = 0;

  void _nextCandidate() {
    if (_currentIndex < widget.candidates.length - 1) {
      setState(() {
        _currentIndex++;
      });
    }
  }

  void _previousCandidate() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
    }
  }

  void _selectCurrentCandidate() {
    if (widget.candidates.isNotEmpty) {
      widget.onCandidateSelected(widget.candidates[_currentIndex]);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.candidates.isEmpty) {
      return Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.people_outline, size: 64.sp, color: Colors.grey[400]),
        SizedBox(height: 16.h),
        Text('Uygun aday bulunamadı',
            style: GoogleFonts.inter(fontSize: 16.sp, color: Colors.grey[600])),
      ]));
    }

    final currentCandidate = widget.candidates[_currentIndex];
    final isSelected = widget.selectedCandidate?.id == currentCandidate.id;

    return Column(children: [
      // Header
      Container(
          padding: EdgeInsets.all(16.w),
          child:
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Eşleştirilecek Kişi',
                style: GoogleFonts.inter(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87)),
            Text('${_currentIndex + 1}/${widget.candidates.length}',
                style: GoogleFonts.inter(
                    fontSize: 14.sp, color: Colors.grey[600])),
          ])),

      // Candidate Card
      Expanded(
          child: Container(
              margin: EdgeInsets.symmetric(horizontal: 16.w),
              child: Card(
                  elevation: isSelected ? 8 : 2,
                  shape: RoundedRectangleBorder(
                      side: BorderSide(
                          color:
                              isSelected ? Colors.purple : Colors.transparent,
                          width: 2)),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Profile Image
                        Expanded(
                            flex: 3,
                            child: Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.vertical()),
                                child: ClipRRect(
                                    borderRadius: BorderRadius.vertical(),
                                    child: CustomImageWidget(
                                        imageUrl: currentCandidate.imageUrl,
                                        fit: BoxFit.cover)))),

                        // Profile Info
                        Expanded(
                            flex: 2,
                            child: Padding(
                                padding: EdgeInsets.all(16.w),
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(children: [
                                        Expanded(
                                            child: Text(
                                                currentCandidate.fullName,
                                                style: GoogleFonts.inter(
                                                    fontSize: 18.sp,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.black87))),
                                        if (currentCandidate.age != null)
                                          Text('${currentCandidate.age}',
                                              style: GoogleFonts.inter(
                                                  fontSize: 16.sp,
                                                  color: Colors.grey[600])),
                                      ]),
                                      SizedBox(height: 4.h),

                                      if (currentCandidate.profession != null)
                                        Text(currentCandidate.profession!,
                                            style: GoogleFonts.inter(
                                                fontSize: 14.sp,
                                                color: Colors.grey[600])),

                                      if (currentCandidate.location !=
                                          null) ...[
                                        SizedBox(height: 4.h),
                                        Row(children: [
                                          Icon(Icons.location_on,
                                              size: 14.sp,
                                              color: Colors.grey[500]),
                                          SizedBox(width: 4.w),
                                          Text(currentCandidate.location!,
                                              style: GoogleFonts.inter(
                                                  fontSize: 12.sp,
                                                  color: Colors.grey[600])),
                                        ]),
                                      ],

                                      SizedBox(height: 8.h),

                                      // Interests
                                      if (currentCandidate.interests != null &&
                                          currentCandidate
                                              .interests!.isNotEmpty)
                                        Wrap(
                                            spacing: 4.w,
                                            runSpacing: 4.h,
                                            children: currentCandidate.interests!
                                                .take(3)
                                                .map((interest) => Container(
                                                    padding: EdgeInsets.symmetric(
                                                        horizontal: 8.w,
                                                        vertical: 2.h),
                                                    decoration: BoxDecoration(
                                                        color:
                                                            Colors.purple[50],
                                                        border: Border.all(
                                                            color: Colors
                                                                .purple[200]!)),
                                                    child: Text(interest,
                                                        style:
                                                            GoogleFonts.inter(fontSize: 11.sp, color: Colors.purple[700]))))
                                                .toList()),
                                    ]))),
                      ])))),

      // Navigation Controls
      Container(
          padding: EdgeInsets.all(16.w),
          child:
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            // Previous Button
            ElevatedButton(
                onPressed: _currentIndex > 0 ? _previousCandidate : null,
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[100],
                    foregroundColor: Colors.grey[700],
                    shape: const CircleBorder(),
                    padding: EdgeInsets.all(12.w)),
                child: Icon(Icons.arrow_back_ios, size: 20.sp)),

            // Select Button
            ElevatedButton(
                onPressed: _selectCurrentCandidate,
                style: ElevatedButton.styleFrom(
                    backgroundColor: isSelected ? Colors.green : Colors.purple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(),
                    padding:
                        EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(isSelected ? Icons.check : Icons.favorite, size: 20.sp),
                  SizedBox(width: 8.w),
                  Text(isSelected ? 'Seçildi' : 'Seç',
                      style: GoogleFonts.inter(
                          fontSize: 14.sp, fontWeight: FontWeight.w600)),
                ])),

            // Next Button
            ElevatedButton(
                onPressed: _currentIndex < widget.candidates.length - 1
                    ? _nextCandidate
                    : null,
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[100],
                    foregroundColor: Colors.grey[700],
                    shape: const CircleBorder(),
                    padding: EdgeInsets.all(12.w)),
                child: Icon(Icons.arrow_forward_ios, size: 20.sp)),
          ])),
    ]);
  }
}
