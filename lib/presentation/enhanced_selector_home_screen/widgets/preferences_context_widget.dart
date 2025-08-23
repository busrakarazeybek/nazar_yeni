import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class PreferencesContextWidget extends StatefulWidget {
  final UserProfile? selectedCandidate;

  const PreferencesContextWidget({
    super.key,
    this.selectedCandidate,
  });

  @override
  State<PreferencesContextWidget> createState() => _PreferencesContextWidgetState();
}

class _PreferencesContextWidgetState extends State<PreferencesContextWidget> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.selectedCandidate == null) {
      return const SizedBox.shrink();
    }

    final hasPreferences = _hasAnyPreferences(widget.selectedCandidate!);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 0.w, vertical: 0.2.h),
      padding: EdgeInsets.all(1.w),
      decoration: BoxDecoration(
        color: hasPreferences
            ? AppTheme.lightTheme.primaryColor.withOpacity(0.06)
            : AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: hasPreferences
              ? AppTheme.lightTheme.primaryColor.withOpacity(0.18)
              : AppTheme.lightTheme.colorScheme.outline.withOpacity(0.12),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: hasPreferences ? () => setState(() => _isExpanded = !_isExpanded) : null,
            child: Row(
              children: [
                Icon(
                  hasPreferences ? Icons.filter_alt : Icons.filter_alt_off,
                  color: hasPreferences
                      ? AppTheme.lightTheme.primaryColor
                      : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  size: 18,
                ),
                SizedBox(width: 1.5.w),
                Expanded(
                  child: Text(
                    hasPreferences
                        ? '${widget.selectedCandidate!.fullName} için tercih filtreleri'
                        : 'Tercih filtresi yok - Karışık gösterim',
                    style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                      color: hasPreferences
                          ? AppTheme.lightTheme.primaryColor
                          : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ),
                if (hasPreferences)
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: AppTheme.lightTheme.primaryColor,
                      size: 20,
                    ),
                  ),
              ],
            ),
          ),
          AnimatedSize(
            duration: Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasPreferences && _isExpanded) ...[
                  SizedBox(height: 1.2.h),
                  _buildPreferencesInfo(),
                ] else if (!hasPreferences) ...[
                  SizedBox(height: 0.7.h),
                  Text(
                    'Bu aday tercihlerini belirtmediği için tüm potansiyel adaylar karışık olarak gösterilecek.',
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
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
    final chips = <Widget>[];
    if (widget.selectedCandidate!.preferredAgeMin != null &&
        widget.selectedCandidate!.preferredAgeMax != null) {
      chips.add(_buildPreferenceChip(
        icon: Icons.calendar_today,
        label: 'Yaş',
        value: '${widget.selectedCandidate!.preferredAgeMin} - ${widget.selectedCandidate!.preferredAgeMax}',
      ));
    }
    if (widget.selectedCandidate!.preferredCities != null &&
        widget.selectedCandidate!.preferredCities!.isNotEmpty) {
      chips.add(_buildPreferenceChip(
        icon: Icons.location_on,
        label: 'Şehirler',
        value: widget.selectedCandidate!.preferredCities!.join(', '),
      ));
    }
    if (widget.selectedCandidate!.preferredGenders != null &&
        widget.selectedCandidate!.preferredGenders!.isNotEmpty) {
      chips.add(_buildPreferenceChip(
        icon: Icons.person,
        label: 'Cinsiyet',
        value: widget.selectedCandidate!.preferredGenders!
            .map((g) => _getGenderDisplayName(g))
            .join(', '),
      ));
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: chips
            .map((chip) => Padding(
                  padding: EdgeInsets.only(right: 1.2.w),
                  child: chip,
                ))
            .toList(),
      ),
    );
  }

  Widget _buildPreferenceChip({required IconData icon, required String label, required String value}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.5.w, vertical: 0.7.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: AppTheme.lightTheme.primaryColor.withOpacity(0.18),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.lightTheme.primaryColor),
          SizedBox(width: 0.8.w),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppTheme.lightTheme.primaryColor,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.lightTheme.colorScheme.onSurface,
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
