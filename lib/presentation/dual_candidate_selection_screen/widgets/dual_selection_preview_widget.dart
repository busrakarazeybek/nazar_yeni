import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class DualSelectionPreviewWidget extends StatelessWidget {
  final String title;
  final UserProfile selectedUser;
  final bool isRecipient;

  const DualSelectionPreviewWidget({
    super.key,
    required this.title,
    required this.selectedUser,
    this.isRecipient = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // Header
      Container(
          padding: EdgeInsets.all(16.w),
          child: Text(title,
              style: GoogleFonts.inter(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: isRecipient ? Colors.purple[700] : Colors.blue[700]),
              textAlign: TextAlign.center)),

      // Profile Preview
      Expanded(
          child: Container(
              margin: EdgeInsets.symmetric(horizontal: 16.w),
              child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                      side: BorderSide(
                          color: isRecipient
                              ? Colors.purple[200]!
                              : Colors.blue[200]!,
                          width: 2)),
                  child: Column(children: [
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
                                    imageUrl: selectedUser.imageUrl,
                                    fit: BoxFit.cover)))),

                    // Profile Info
                    Expanded(
                        flex: 2,
                        child: Padding(
                            padding: EdgeInsets.all(16.w),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(children: [
                                    Expanded(
                                        child: Text(selectedUser.fullName,
                                            style: GoogleFonts.inter(
                                                fontSize: 16.sp,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.black87))),
                                    if (selectedUser.age != null)
                                      Text('${selectedUser.age}',
                                          style: GoogleFonts.inter(
                                              fontSize: 14.sp,
                                              color: Colors.grey[600])),
                                  ]),
                                  SizedBox(height: 4.h),

                                  if (selectedUser.profession != null)
                                    Text(selectedUser.profession!,
                                        style: GoogleFonts.inter(
                                            fontSize: 12.sp,
                                            color: Colors.grey[600])),

                                  if (selectedUser.location != null) ...[
                                    SizedBox(height: 4.h),
                                    Row(children: [
                                      Icon(Icons.location_on,
                                          size: 12.sp, color: Colors.grey[500]),
                                      SizedBox(width: 2.w),
                                      Expanded(
                                          child: Text(selectedUser.location!,
                                              style: GoogleFonts.inter(
                                                  fontSize: 11.sp,
                                                  color: Colors.grey[600]))),
                                    ]),
                                  ],

                                  SizedBox(height: 8.h),

                                  // Interests
                                  if (selectedUser.interests != null && selectedUser.interests!.isNotEmpty)
                                    Wrap(
                                        spacing: 3.w,
                                        runSpacing: 3.h,
                                        children: selectedUser.interests!
                                            .take(2)
                                            .map((interest) => Container(
                                                padding: EdgeInsets.symmetric(
                                                    horizontal: 6.w,
                                                    vertical: 2.h),
                                                decoration: BoxDecoration(
                                                    color: isRecipient
                                                        ? Colors.purple[50]
                                                        : Colors.blue[50],
                                                    border: Border.all(
                                                        color: isRecipient
                                                            ? Colors
                                                                .purple[200]!
                                                            : Colors
                                                                .blue[200]!)),
                                                child: Text(interest,
                                                    style: GoogleFonts.inter(
                                                        fontSize: 10.sp,
                                                        color: isRecipient ? Colors.purple[700] : Colors.blue[700]))))
                                            .toList()),
                                ]))),
                  ])))),

      // Status Indicator
      Container(
          margin: EdgeInsets.all(16.w),
          padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 12.w),
          decoration: BoxDecoration(
              color: isRecipient ? Colors.purple[50] : Colors.blue[50],
              border: Border.all(
                  color:
                      isRecipient ? Colors.purple[200]! : Colors.blue[200]!)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.check_circle,
                size: 16.sp,
                color: isRecipient ? Colors.purple[600] : Colors.blue[600]),
            SizedBox(width: 4.w),
            Text('Seçildi',
                style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                    color:
                        isRecipient ? Colors.purple[700] : Colors.blue[700])),
          ])),
    ]);
  }
}
