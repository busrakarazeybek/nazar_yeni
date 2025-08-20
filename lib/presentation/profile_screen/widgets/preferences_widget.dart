import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class PreferencesWidget extends StatefulWidget {
  final Map<String, dynamic> userData;
  final VoidCallback onDataChanged;

  const PreferencesWidget({
    super.key,
    required this.userData,
    required this.onDataChanged,
  });

  @override
  State<PreferencesWidget> createState() => _PreferencesWidgetState();
}

class _PreferencesWidgetState extends State<PreferencesWidget> {
  final TextEditingController _customCityController = TextEditingController();
  
  List<String> get _preferredCities => 
      (widget.userData["preferredCities"] as List<dynamic>?)?.cast<String>() ?? [];
  
  List<String> get _preferredGenders {
    final genders = (widget.userData["preferredGenders"] as List<dynamic>?)?.cast<String>() ?? [];
    print("DEBUG: _preferredGenders = $genders");
    return genders;
  }

  final List<String> _availableCities = [
    'İstanbul', 'Ankara', 'İzmir', 'Bursa', 'Antalya', 'Adana',
    'Konya', 'Gaziantep', 'Mersin', 'Kayseri', 'Diyarbakır', 'Samsun',
    'Denizli', 'Şanlıurfa', 'Adapazarı', 'Malatya', 'Kahramanmaraş', 'Van'
  ];

  final List<String> _availableGenders = ['Erkek', 'Kadın', 'Diğer'];

  @override
  void dispose() {
    _customCityController.dispose();
    super.dispose();
  }

  void _updatePreferences() {
    widget.onDataChanged();
  }

  void _addCustomCity() {
    final cityName = _customCityController.text.trim();
    if (cityName.isNotEmpty && !_preferredCities.contains(cityName)) {
      setState(() {
        _preferredCities.add(cityName);
        _customCityController.clear();
      });
      _updatePreferences();
    }
  }

  void _removeCity(String city) {
    setState(() {
      _preferredCities.remove(city);
    });
    _updatePreferences();
  }

  void _toggleGender(String gender) {
    setState(() {
      final currentGenders = List<String>.from(_preferredGenders);
      if (currentGenders.contains(gender)) {
        currentGenders.remove(gender);
      } else {
        currentGenders.add(gender);
      }
      widget.userData["preferredGenders"] = currentGenders;
    });
    _updatePreferences();
  }

  void _updateAgeRange(RangeValues values) {
    setState(() {
      widget.userData["preferredAgeMin"] = values.start.round();
      widget.userData["preferredAgeMax"] = values.end.round();
    });
    _updatePreferences();
  }

  @override
  Widget build(BuildContext context) {
    final preferredAgeMin = (widget.userData["preferredAgeMin"] as int?) ?? 18;
    final preferredAgeMax = (widget.userData["preferredAgeMax"] as int?) ?? 65;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowLight,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CustomIconWidget(
                iconName: 'tune',
                color: AppTheme.lightTheme.primaryColor,
                size: 24,
              ),
              SizedBox(width: 2.w),
              Text(
                'Eşleşme Tercihleri',
                style: AppTheme.lightTheme.textTheme.titleMedium,
              ),
            ],
          ),
          SizedBox(height: 3.h),

          // Age Range Preference
          _buildAgeRangeSection(preferredAgeMin, preferredAgeMax),
          
          SizedBox(height: 3.h),

          // Gender Preferences
          _buildGenderPreferencesSection(),
          
          SizedBox(height: 3.h),

          // City Preferences
          _buildCityPreferencesSection(),
        ],
      ),
    );
  }

  Widget _buildAgeRangeSection(int minAge, int maxAge) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tercih Edilen Yaş Aralığı',
          style: AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 2.h),
        Container(
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: AppTheme.lightTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.lightTheme.primaryColor.withOpacity(0.3),
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$minAge yaş',
                    style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.lightTheme.primaryColor,
                    ),
                  ),
                  Text(
                    '$maxAge yaş',
                    style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.lightTheme.primaryColor,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 2.h),
              RangeSlider(
                values: RangeValues(minAge.toDouble(), maxAge.toDouble()),
                min: 18,
                max: 65,
                divisions: 47,
                activeColor: AppTheme.lightTheme.primaryColor,
                inactiveColor: AppTheme.lightTheme.primaryColor.withOpacity(0.3),
                labels: RangeLabels('$minAge', '$maxAge'),
                onChanged: _updateAgeRange,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGenderPreferencesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tercih Edilen Cinsiyet',
          style: AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 2.h),
        Wrap(
          spacing: 2.w,
          runSpacing: 1.h,
          children: _availableGenders.map((gender) {
            final isSelected = _preferredGenders.contains(gender);
            return GestureDetector(
              onTap: () => _toggleGender(gender),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? AppTheme.lightTheme.primaryColor 
                      : AppTheme.lightTheme.colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected 
                        ? AppTheme.lightTheme.primaryColor 
                        : AppTheme.lightTheme.colorScheme.outline.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSelected) ...[
                      Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 16,
                      ),
                      SizedBox(width: 1.w),
                    ],
                    Text(
                      gender,
                      style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                        color: isSelected 
                            ? Colors.white 
                            : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCityPreferencesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tercih Edilen Şehirler',
          style: AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 1.h),
        Text(
          'Adaylarınızı hangi şehirlerden seçmek istersiniz?',
          style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            fontStyle: FontStyle.italic,
          ),
        ),
        SizedBox(height: 2.h),

        // Custom city input
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _customCityController,
                decoration: InputDecoration(
                  hintText: 'Şehir adı yazın ve Enter\'a basın...',
                  prefixIcon: Icon(Icons.location_city_outlined),
                  filled: true,
                  fillColor: AppTheme.lightTheme.colorScheme.surfaceVariant,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppTheme.lightTheme.primaryColor,
                      width: 2,
                    ),
                  ),
                ),
                onFieldSubmitted: (value) => _addCustomCity(),
              ),
            ),
            SizedBox(width: 2.w),
            GestureDetector(
              onTap: _addCustomCity,
              child: Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.primaryColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.add, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),

        SizedBox(height: 2.h),

        // Available cities
        Text(
          'Popüler Şehirler:',
          style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 1.h),
        Wrap(
          spacing: 2.w,
          runSpacing: 1.h,
          children: _availableCities.map((city) {
            final isSelected = _preferredCities.contains(city);
            return GestureDetector(
              onTap: () {
                if (isSelected) {
                  _removeCity(city);
                } else {
                  setState(() {
                    _preferredCities.add(city);
                  });
                  _updatePreferences();
                }
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.8.h),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? AppTheme.lightTheme.primaryColor 
                      : AppTheme.lightTheme.colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected 
                        ? AppTheme.lightTheme.primaryColor 
                        : AppTheme.lightTheme.colorScheme.outline.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  city,
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: isSelected 
                        ? Colors.white 
                        : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        // Selected cities display
        if (_preferredCities.isNotEmpty) ...[
          SizedBox(height: 2.h),
          Text(
            'Seçilen Şehirler:',
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 1.h),
          Wrap(
            spacing: 2.w,
            runSpacing: 1.h,
            children: _preferredCities.map((city) {
              return Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.8.h),
                decoration: BoxDecoration(
                  color: AppTheme.successColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      city,
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(width: 1.w),
                    GestureDetector(
                      onTap: () => _removeCity(city),
                      child: Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}