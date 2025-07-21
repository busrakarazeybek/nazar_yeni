import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class EmptyMatchesWidget extends StatelessWidget {
  final String userRole;
  final bool isFiltered;

  const EmptyMatchesWidget({
    super.key,
    required this.userRole,
    this.isFiltered = false,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Illustration
            Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: CustomIconWidget(
                iconName: isFiltered ? 'search_off' : 'favorite_border',
                color: AppTheme.lightTheme.primaryColor,
                size: 20.w,
              ),
            ),

            SizedBox(height: 24),

            // Title
            Text(
              _getTitle(),
              style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryLight,
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 12),

            // Description
            Text(
              _getDescription(),
              style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                color: AppTheme.textSecondaryLight,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 32),

            // Action Button
            if (!isFiltered) _buildActionButton(context),
          ],
        ),
      ),
    );
  }

  String _getTitle() {
    if (isFiltered) {
      return 'Sonuç Bulunamadı';
    }

    if (userRole == 'Selector') {
      return 'Henüz Eşleşme Yok';
    } else {
      return 'Henüz Talep Yok';
    }
  }

  String _getDescription() {
    if (isFiltered) {
      return 'Arama kriterlerinize uygun eşleşme bulunamadı. Farklı filtreler deneyebilirsiniz.';
    }

    if (userRole == 'Selector') {
      return 'Henüz hiç eşleşme talebi göndermediniz. Uygun adayları keşfetmek için ana sayfaya göz atın.';
    } else {
      return 'Henüz size gönderilen bir eşleşme talebi yok. Seçicilerinizin sizin için uygun eşleşmeler bulmasını bekleyin.';
    }
  }

  Widget _buildActionButton(BuildContext context) {
    if (userRole == 'Selector') {
      return ElevatedButton.icon(
        onPressed: () {
          Navigator.pushNamed(context, '/enhanced-selector-home-screen');
        },
        icon: CustomIconWidget(
          iconName: 'search',
          color: Colors.white,
          size: 20,
        ),
        label: Text('Adayları Keşfet'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.lightTheme.primaryColor,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } else {
      return OutlinedButton.icon(
        onPressed: () {
          Navigator.pushNamed(context, '/my-selectors-screen');
        },
        icon: CustomIconWidget(
          iconName: 'people',
          color: AppTheme.lightTheme.primaryColor,
          size: 20,
        ),
        label: Text('Seçicilerimi Görüntüle'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.lightTheme.primaryColor,
          side: BorderSide(
            color: AppTheme.lightTheme.primaryColor,
            width: 1,
          ),
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }
}
