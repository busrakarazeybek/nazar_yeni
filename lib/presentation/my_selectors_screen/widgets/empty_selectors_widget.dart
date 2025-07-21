import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class EmptySelectorsWidget extends StatelessWidget {
  final VoidCallback onAddSelector;

  const EmptySelectorsWidget({
    super.key,
    required this.onAddSelector,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(6.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Illustration
            Container(
              width: 60.w,
              height: 40.h,
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.primaryContainer
                    .withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomIconWidget(
                    iconName: 'people_outline',
                    color: AppTheme.lightTheme.colorScheme.primary,
                    size: 80,
                  ),
                  SizedBox(height: 2.h),
                  CustomIconWidget(
                    iconName: 'favorite',
                    color: AppTheme.accentColor,
                    size: 40,
                  ),
                ],
              ),
            ),
            SizedBox(height: 4.h),

            // Title
            Text(
              "Henüz Görücünüz Yok",
              style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.lightTheme.colorScheme.primary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 2.h),

            // Description
            Text(
              "Görücüler, sizin için uygun eşleri bulup önerebilecek güvenilir kişilerdir. Aile üyelerinizi veya yakın arkadaşlarınızı görücü olarak davet edebilirsiniz.",
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 3.h),

            // Benefits
            Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.lightTheme.colorScheme.outline
                      .withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    "Görücü Avantajları",
                    style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.lightTheme.colorScheme.primary,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  _buildBenefitItem(
                    "Güvenilir Eşleşmeler",
                    "Sizi tanıyan kişiler daha uygun eşler önerir",
                    'verified',
                  ),
                  SizedBox(height: 1.5.h),
                  _buildBenefitItem(
                    "Kültürel Uyum",
                    "Geleneksel değerlerinize uygun öneriler",
                    'favorite',
                  ),
                  SizedBox(height: 1.5.h),
                  _buildBenefitItem(
                    "Aile Desteği",
                    "Ailenizin onayladığı ilişkiler",
                    'family_restroom',
                  ),
                ],
              ),
            ),
            SizedBox(height: 4.h),

            // Call to Action
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onAddSelector,
                icon: CustomIconWidget(
                  iconName: 'person_add',
                  color: AppTheme
                          .lightTheme.elevatedButtonTheme.style?.foregroundColor
                          ?.resolve({}) ??
                      Colors.white,
                  size: 20,
                ),
                label: const Text("İlk Görücünüzü Ekleyin"),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 2.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            SizedBox(height: 2.h),

            // Secondary Action
            TextButton.icon(
              onPressed: () {
                _showHowItWorks(context);
              },
              icon: CustomIconWidget(
                iconName: 'help_outline',
                color: AppTheme.lightTheme.colorScheme.primary,
                size: 18,
              ),
              label: const Text("Nasıl Çalışır?"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitItem(String title, String description, String iconName) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(2.w),
          decoration: BoxDecoration(
            color: AppTheme.lightTheme.colorScheme.primaryContainer
                .withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: CustomIconWidget(
            iconName: iconName,
            color: AppTheme.lightTheme.colorScheme.primary,
            size: 20,
          ),
        ),
        SizedBox(width: 3.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 0.5.h),
              Text(
                description,
                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showHowItWorks(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Nasıl Çalışır?"),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStep("1", "Görücü Davet Edin",
                  "Güvendiğiniz aile üyesi veya arkadaşınızı davet edin."),
              SizedBox(height: 2.h),
              _buildStep("2", "Profil Erişimi",
                  "Görücünüz sizin profilinizi görüp uygun eşleri arayabilir."),
              SizedBox(height: 2.h),
              _buildStep("3", "Eşleşme Önerileri",
                  "Görücünüz beğendiği profilleri size önerir."),
              SizedBox(height: 2.h),
              _buildStep("4", "Onay Süreci",
                  "Siz de önerilen profilleri onaylayıp eşleşme sağlarsınız."),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Anladım"),
          ),
        ],
      ),
    );
  }

  Widget _buildStep(String number, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 6.w,
          height: 6.w,
          decoration: BoxDecoration(
            color: AppTheme.lightTheme.colorScheme.primary,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        SizedBox(width: 3.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 0.5.h),
              Text(
                description,
                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
