import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class PreferencesContextWidget extends StatelessWidget {
  final UserProfile? selectedCandidate;

  const PreferencesContextWidget({
    super.key,
    this.selectedCandidate,
  });

  @override
  Widget build(BuildContext context) {
    if (selectedCandidate == null) {
      return const SizedBox.shrink();
    }

    final hasPreferences = _hasAnyPreferences(selectedCandidate!);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: hasPreferences
            ? AppTheme.lightTheme.primaryColor.withValues(alpha: 0.1)
            : AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12.w),
        border: Border.all(
          color: hasPreferences
              ? AppTheme.lightTheme.primaryColor.withValues(alpha: 0.3)
              : AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasPreferences ? Icons.filter_alt : Icons.filter_alt_off,
                color: hasPreferences
                    ? AppTheme.lightTheme.primaryColor
                    : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                size: 20.w,
              ),
              SizedBox(width: 2.w),
              Text(
                hasPreferences
                    ? '${selectedCandidate!.fullName} için tercih filtreleri'
                    : 'Tercih filtresi yok - Karışık gösterim',
                style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                  color: hasPreferences
                      ? AppTheme.lightTheme.primaryColor
                      : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (hasPreferences) ...[
            SizedBox(height: 2.h),
            _buildPreferencesInfo(),
          ] else ...[
            SizedBox(height: 1.h),
            Text(
              'Bu aday tercihlerini belirtmediği için tüm potansiyel adaylar karışık olarak gösterilecek.',
              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  bool _hasAnyPreferences(UserProfile candidate) {
    return (candidate.preferredAgeMin != null &&
            candidate.preferredAgeMax != null) ||
        (candidate.preferredCities != null &&
            candidate.preferredCities!.isNotEmpty) ||
        (candidate.preferredGenders != null &&
            candidate.preferredGenders!.isNotEmpty);
  }

  Widget _buildPreferencesInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (selectedCandidate!.preferredAgeMin != null &&
            selectedCandidate!.preferredAgeMax != null)
          _buildPreferenceRow(
            'Yaş Aralığı',
            '${selectedCandidate!.preferredAgeMin} - ${selectedCandidate!.preferredAgeMax}',
            Icons.calendar_today,
          ),
        if (selectedCandidate!.preferredCities != null &&
            selectedCandidate!.preferredCities!.isNotEmpty)
          _buildPreferenceRow(
            'Şehirler',
            selectedCandidate!.preferredCities!.join(', '),
            Icons.location_on,
          ),
        if (selectedCandidate!.preferredGenders != null &&
            selectedCandidate!.preferredGenders!.isNotEmpty)
          _buildPreferenceRow(
            'Cinsiyetler',
            selectedCandidate!.preferredGenders!
                .map((g) => _getGenderDisplayName(g))
                .join(', '),
            Icons.person,
          ),
      ],
    );
  }

  Widget _buildPreferenceRow(String title, String value, IconData icon) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 16.w,
            color: AppTheme.lightTheme.primaryColor,
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getGenderDisplayName(String gender) {
    switch (gender.toLowerCase()) {
      case 'male':
      case 'erkek':
        return 'Erkek';
      case 'female':
      case 'kadın':
        return 'Kadın';
      case 'other':
      case 'diğer':
        return 'Diğer';
      default:
        return gender;
    }
  }
}
