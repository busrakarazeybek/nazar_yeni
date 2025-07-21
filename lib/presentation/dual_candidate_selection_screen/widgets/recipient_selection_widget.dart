import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class RecipientSelectionWidget extends StatelessWidget {
  final List<UserProfile> assignedCandidates;
  final UserProfile? selectedRecipient;
  final Function(UserProfile?) onRecipientSelected;

  const RecipientSelectionWidget({
    super.key,
    required this.assignedCandidates,
    required this.selectedRecipient,
    required this.onRecipientSelected,
  });

  // Example users to show when no assigned candidates exist
  List<UserProfile> get _exampleUsers => [
        UserProfile(
          id: 'example_1',
          email: 'ayse@example.com',
          fullName: 'Ayşe Demir',
          role: UserRole.candidate,
          age: 28,
          gender: GenderType.female,
          location: 'İstanbul',
          profession: 'Mühendis',
          imageUrl:
              'https://images.pexels.com/photos/774909/pexels-photo-774909.jpeg',
          createdAt: DateTime.now(),
        ),
        UserProfile(
          id: 'example_2',
          email: 'mehmet@example.com',
          fullName: 'Mehmet Yılmaz',
          role: UserRole.candidate,
          age: 32,
          gender: GenderType.male,
          location: 'Ankara',
          profession: 'Doktor',
          imageUrl:
              'https://images.pexels.com/photos/220453/pexels-photo-220453.jpeg',
          createdAt: DateTime.now(),
        ),
        UserProfile(
          id: 'example_3',
          email: 'zeynep@example.com',
          fullName: 'Zeynep Kaya',
          role: UserRole.candidate,
          age: 26,
          gender: GenderType.female,
          location: 'İzmir',
          profession: 'Öğretmen',
          imageUrl:
              'https://images.pexels.com/photos/415829/pexels-photo-415829.jpeg',
          createdAt: DateTime.now(),
        ),
        UserProfile(
          id: 'example_4',
          email: 'ali@example.com',
          fullName: 'Ali Çelik',
          role: UserRole.candidate,
          age: 30,
          gender: GenderType.male,
          location: 'Bursa',
          profession: 'Avukat',
          imageUrl:
              'https://images.pexels.com/photos/1222271/pexels-photo-1222271.jpeg',
          createdAt: DateTime.now(),
        ),
      ];

  List<UserProfile> get _displayCandidates =>
      assignedCandidates.isEmpty ? _exampleUsers : assignedCandidates;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Kimin için seçiyorsun?',
          style: GoogleFonts.inter(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black87)),
      SizedBox(height: 12.h),
      if (assignedCandidates.isEmpty)
        Container(
            padding: EdgeInsets.all(12.w),
            margin: EdgeInsets.only(bottom: 16.h),
            decoration: BoxDecoration(
                color: Colors.blue[50],
                border: Border.all(color: Colors.blue[200]!),
                borderRadius: BorderRadius.circular(8)),
            child: Row(children: [
              Icon(Icons.info_outline, color: Colors.blue[600], size: 18.sp),
              SizedBox(width: 8.w),
              Expanded(
                  child: Text(
                      'Örnek adaylar gösteriliyor. Gerçek adaylarınız atandığında burada görünecek.',
                      style: GoogleFonts.inter(
                          fontSize: 12.sp, color: Colors.blue[700]))),
            ])),
      Container(
          decoration:
              BoxDecoration(border: Border.all(color: Colors.grey[300]!)),
          child: DropdownButtonHideUnderline(
              child: DropdownButton<UserProfile>(
                  value: selectedRecipient,
                  hint: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12.w),
                      child: Text('Bir aday seçin...',
                          style: GoogleFonts.inter(
                              fontSize: 14.sp, color: Colors.grey[600]))),
                  isExpanded: true,
                  icon: Padding(
                      padding: EdgeInsets.only(right: 12.w),
                      child: Icon(Icons.keyboard_arrow_down,
                          color: Colors.grey[600])),
                  items: _displayCandidates.map((candidate) {
                    return DropdownMenuItem<UserProfile>(
                        value: candidate,
                        child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12.w),
                            child: Row(children: [
                              ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: CustomImageWidget(
                                      imageUrl: candidate.imageUrl,
                                      width: 40.w,
                                      height: 40.h,
                                      fit: BoxFit.cover)),
                              SizedBox(width: 12.w),
                              Expanded(
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                    Text(candidate.fullName,
                                        style: GoogleFonts.inter(
                                            fontSize: 14.sp,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.black87)),
                                    if (candidate.age != null &&
                                        candidate.location != null)
                                      Text(
                                          '${candidate.age} • ${candidate.location}',
                                          style: GoogleFonts.inter(
                                              fontSize: 12.sp,
                                              color: Colors.grey[600])),
                                  ])),
                              if (assignedCandidates.isEmpty)
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 6.w, vertical: 2.h),
                                  decoration: BoxDecoration(
                                    color: Colors.orange[100],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text('Örnek',
                                      style: GoogleFonts.inter(
                                          fontSize: 10.sp,
                                          color: Colors.orange[700],
                                          fontWeight: FontWeight.w500)),
                                ),
                            ])));
                  }).toList(),
                  onChanged: onRecipientSelected,
                  dropdownColor: Colors.white,
                  menuMaxHeight: 300.h))),
      if (selectedRecipient != null) ...[
        SizedBox(height: 12.h),
        Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
                color: Colors.purple[50],
                border: Border.all(color: Colors.purple[200]!),
                borderRadius: BorderRadius.circular(8)),
            child: Row(children: [
              ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: CustomImageWidget(
                      imageUrl: selectedRecipient!.imageUrl,
                      width: 40.w,
                      height: 40.h,
                      fit: BoxFit.cover)),
              SizedBox(width: 12.w),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(selectedRecipient!.fullName,
                        style: GoogleFonts.inter(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.purple[800])),
                    if (selectedRecipient!.profession != null)
                      Text(selectedRecipient!.profession!,
                          style: GoogleFonts.inter(
                              fontSize: 12.sp, color: Colors.purple[600])),
                  ])),
              Icon(Icons.check_circle, color: Colors.purple[600], size: 20.sp),
            ])),
      ],
    ]);
  }
}
