import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../widgets/image_picker_widget.dart';

class ProfileHeaderWidget extends StatefulWidget {
  final Map<String, dynamic> userData;
  final VoidCallback onImageChanged;

  const ProfileHeaderWidget({
    super.key,
    required this.userData,
    required this.onImageChanged,
  });

  @override
  State<ProfileHeaderWidget> createState() => _ProfileHeaderWidgetState();
}

class _ProfileHeaderWidgetState extends State<ProfileHeaderWidget> {
  
  void _onImageSelected(String imageUrl) {
    // Update user data with new image URL
    widget.userData['imageUrl'] = imageUrl;
    widget.onImageChanged();
    
    // Refresh the AuthProvider with updated profile
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    authProvider.refreshUserProfile();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUserProfile;
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.lightTheme.primaryColor,
            AppTheme.lightTheme.primaryColor.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(8.w),
          bottomRight: Radius.circular(8.w),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.lightTheme.primaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 2.h),
            
            // Profile Image with Upload Functionality
            Container(
              width: 35.w,
              height: 35.w,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
              ),
              child: Icon(
                Icons.person, 
                color: Colors.grey[600], 
                size: 20.w,
              ),
            ),
            
            SizedBox(height: 3.h),
            
            // User Name
            Text(
              widget.userData['name'] ?? 'Kullanıcı',
              style: TextStyle(
                fontSize: 22.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            
            SizedBox(height: 1.h),
            
            // User Role
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: 4.w,
                vertical: 1.h,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                _getRoleDisplayName(widget.userData['role']),
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            
            SizedBox(height: 2.h),
            
            // User Stats Row
            _buildStatsRow(),
            
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatItem(
          icon: Icons.favorite,
          label: 'Eşleşmeler',
          value: widget.userData['matchCount']?.toString() ?? '0',
        ),
        Container(
          width: 1,
          height: 6.h,
          color: Colors.white.withOpacity(0.3),
        ),
        _buildStatItem(
          icon: Icons.photo_library,
          label: 'Fotoğraflar',
          value: widget.userData['photoCount']?.toString() ?? '0',
        ),
        Container(
          width: 1,
          height: 6.h,
          color: Colors.white.withOpacity(0.3),
        ),
        _buildStatItem(
          icon: Icons.star,
          label: 'Puan',
          value: widget.userData['rating']?.toString() ?? '0.0',
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(2.w),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 6.w,
          ),
        ),
        SizedBox(height: 1.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10.sp,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  String _getRoleDisplayName(String? role) {
    switch (role) {
      case 'candidate':
        return 'Aday';
      case 'selector':
        return 'Seçici';
      case 'admin':
        return 'Admin';
      default:
        return 'Kullanıcı';
    }
  }
}