import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class CulturalInfoBottomSheet extends StatelessWidget {
  const CulturalInfoBottomSheet({super.key});

  final List<Map<String, dynamic>> _culturalInfo = const [
    {
      "title": "Geleneksel Görücü Usulü",
      "description":
          "Türk kültüründe yüzyıllardır süregelen, ailelerin ve güvenilir kişilerin aracılık ettiği evlilik geleneği.",
      "icon": "history",
    },
    {
      "title": "Güven ve Saygı",
      "description":
          "Aile büyüklerinin ve dostların önerileriyle, karşılıklı saygıya dayalı ilişkiler kurulması.",
      "icon": "verified_user",
    },
    {
      "title": "Modern Uyarlama",
      "description":
          "Geleneksel değerleri koruyarak, teknolojinin avantajlarından faydalanan çağdaş yaklaşım.",
      "icon": "smartphone",
    },
    {
      "title": "Kültürel Değerler",
      "description":
          "Aile bağları, karşılıklı saygı ve uzun vadeli ilişki hedefleri ön planda tutulur.",
      "icon": "favorite",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 85.h,
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          _buildHandle(),
          _buildHeader(),
          Expanded(
            child: _buildContent(),
          ),
          _buildCloseButton(context),
        ],
      ),
    );
  }

  Widget _buildHandle() {
    return Container(
      margin: EdgeInsets.only(top: 2.h),
      width: 12.w,
      height: 0.5.h,
      decoration: BoxDecoration(
        color: AppTheme.borderLight,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryLight,
                  AppTheme.primaryLight.withValues(alpha: 0.8),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: CustomIconWidget(
              iconName: 'info',
              color: Colors.white,
              size: 32,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            'Görücü Usulü Nedir?',
            style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
              color: AppTheme.primaryLight,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 1.h),
          Text(
            'Türk kültürünün değerli geleneğini modern teknoloji ile buluşturan yaklaşımımızı keşfedin',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondaryLight,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 6.w),
      child: Column(
        children: [
          ..._culturalInfo.map((info) => _buildInfoCard(info)),
          SizedBox(height: 4.h),
          _buildQuoteSection(),
          SizedBox(height: 4.h),
        ],
      ),
    );
  }

  Widget _buildInfoCard(Map<String, dynamic> info) {
    return Container(
      margin: EdgeInsets.only(bottom: 3.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryLight.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowLight,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: AppTheme.secondaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: CustomIconWidget(
              iconName: info["icon"] as String,
              color: AppTheme.primaryLight,
              size: 24,
            ),
          ),
          SizedBox(width: 4.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  info["title"] as String,
                  style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                    color: AppTheme.primaryLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 1.h),
                Text(
                  info["description"] as String,
                  style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondaryLight,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuoteSection() {
    return Container(
      padding: EdgeInsets.all(5.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.secondaryLight,
            AppTheme.secondaryLight.withValues(alpha: 0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryLight.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          CustomIconWidget(
            iconName: 'format_quote',
            color: AppTheme.primaryLight.withValues(alpha: 0.6),
            size: 32,
          ),
          SizedBox(height: 2.h),
          Text(
            '"Geleneksel değerlerimizi koruyarak, modern dünyanın imkanlarından faydalanıyoruz. Güven, saygı ve aile bağları temelinde kurulan ilişkiler, en sağlam temellere sahiptir."',
            style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
              color: AppTheme.primaryLight,
              fontStyle: FontStyle.italic,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 2.h),
          Container(
            width: 20.w,
            height: 0.5.h,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  AppTheme.primaryLight.withValues(alpha: 0.5),
                  Colors.transparent,
                ],
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCloseButton(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(6.w),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryLight,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 2.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
          ),
          child: Text(
            'Anladım',
            style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
