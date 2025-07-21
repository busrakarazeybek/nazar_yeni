import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';

class SelectorMessageWidget extends StatelessWidget {
  final String message;
  final String selectorName;

  const SelectorMessageWidget({
    super.key,
    required this.message,
    required this.selectorName,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(),
        child: Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                  Colors.amber[50]!,
                  Colors.orange[50]!,
                ])),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                        color: Colors.orange[100], shape: BoxShape.circle),
                    child: Icon(Icons.format_quote,
                        color: Colors.orange[700], size: 16.sp)),
                SizedBox(width: 12.w),
                Expanded(
                    child: Text('$selectorName\'nin Mesajı',
                        style: GoogleFonts.inter(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange[800]))),
              ]),
              SizedBox(height: 12.h),
              Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                      color: Colors.white.withAlpha(179),
                      border: Border.all(color: Colors.orange[200]!)),
                  child: Text('"$message"',
                      style: GoogleFonts.inter(
                          fontSize: 14.sp,
                          color: Colors.grey[700],
                          height: 1.5,
                          fontStyle: FontStyle.italic))),
              SizedBox(height: 8.h),
              Row(children: [
                Icon(Icons.psychology, color: Colors.orange[600], size: 14.sp),
                SizedBox(width: 4.w),
                Expanded(
                    child: Text('Bu eşleştirme neden önerildi',
                        style: GoogleFonts.inter(
                            fontSize: 12.sp,
                            color: Colors.orange[700],
                            fontWeight: FontWeight.w500))),
              ]),
            ])));
  }
}
