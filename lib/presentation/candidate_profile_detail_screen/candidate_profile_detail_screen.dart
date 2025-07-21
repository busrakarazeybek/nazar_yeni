import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import './widgets/action_buttons_widget.dart';
import './widgets/interest_tags_widget.dart';
import './widgets/profile_image_gallery_widget.dart';
import './widgets/profile_info_section_widget.dart';

class CandidateProfileDetailScreen extends StatefulWidget {
  const CandidateProfileDetailScreen({super.key});

  @override
  State<CandidateProfileDetailScreen> createState() =>
      _CandidateProfileDetailScreenState();
}

class _CandidateProfileDetailScreenState
    extends State<CandidateProfileDetailScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isAppBarCollapsed = false;

  // Mock candidate data
  final Map<String, dynamic> candidateData = {
    "id": 1,
    "name": "Ayşe Demir",
    "age": 28,
    "location": "İstanbul, Türkiye",
    "bio":
        "Merhaba! Ben Ayşe, 28 yaşındayım ve İstanbul'da yaşıyorum. Kitap okumayı, doğa yürüyüşlerini ve yeni yerler keşfetmeyi seviyorum. Aileme ve arkadaşlarıma çok değer veririm. Hayatımda samimi ve güvenilir bir partner arıyorum.",
    "interests": [
      "Kitap Okuma",
      "Doğa Yürüyüşü",
      "Seyahat",
      "Müzik",
      "Yemek Pişirme",
      "Fotoğrafçılık",
      "Yoga",
      "Sinema"
    ],
    "images": [
      "https://images.pexels.com/photos/774909/pexels-photo-774909.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1",
      "https://images.pexels.com/photos/1130626/pexels-photo-1130626.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1",
      "https://images.pexels.com/photos/1239291/pexels-photo-1239291.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1",
      "https://images.pexels.com/photos/1858175/pexels-photo-1858175.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1"
    ],
    "education": "İstanbul Üniversitesi - İşletme",
    "profession": "Pazarlama Uzmanı",
    "height": "165 cm",
    "religion": "İslam",
    "smoking": "Hayır",
    "drinking": "Hayır"
  };

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    const double threshold = 200.0;
    final bool isCollapsed = _scrollController.offset > threshold;

    if (isCollapsed != _isAppBarCollapsed) {
      setState(() {
        _isAppBarCollapsed = isCollapsed;
      });
    }
  }

  Future<void> _onRefresh() async {
    // Simulate refresh delay
    await Future.delayed(const Duration(seconds: 1));
    // In real app, this would refresh profile data
  }

  void _onPassPressed() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Geç',
            style: AppTheme.lightTheme.textTheme.titleLarge,
          ),
          content: Text(
            'Bu profili geçmek istediğinizden emin misiniz?',
            style: AppTheme.lightTheme.textTheme.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'İptal',
                style: TextStyle(color: AppTheme.textSecondaryLight),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // Return to browse screen
              },
              child: Text(
                'Geç',
                style: TextStyle(color: AppTheme.errorColor),
              ),
            ),
          ],
        );
      },
    );
  }

  void _onSendMatchRequest() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Eşleşme İsteği Gönder',
            style: AppTheme.lightTheme.textTheme.titleLarge,
          ),
          content: Text(
            '${candidateData["name"]} adlı kişiye eşleşme isteği göndermek istediğinizden emin misiniz?',
            style: AppTheme.lightTheme.textTheme.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'İptal',
                style: TextStyle(color: AppTheme.textSecondaryLight),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showSuccessMessage();
              },
              child: const Text('Gönder'),
            ),
          ],
        );
      },
    );
  }

  void _showSuccessMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Eşleşme isteği başarıyla gönderildi!',
          style: AppTheme.lightTheme.snackBarTheme.contentTextStyle,
        ),
        backgroundColor: AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
    );

    // Navigate back after showing success message
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: AppTheme.primaryLight,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverAppBar(
              expandedHeight: 50.h,
              floating: false,
              pinned: true,
              elevation: 0,
              backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
              leading: Container(
                margin: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.scaffoldBackgroundColor
                      .withValues(alpha: 0.8),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: CustomIconWidget(
                    iconName: 'arrow_back',
                    color: AppTheme.textPrimaryLight,
                    size: 6.w,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              flexibleSpace: FlexibleSpaceBar(
                title: _isAppBarCollapsed
                    ? Text(
                        candidateData["name"] as String,
                        style:
                            AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                          color: AppTheme.textPrimaryLight,
                          fontSize: 16.sp,
                        ),
                      )
                    : null,
                background: ProfileImageGalleryWidget(
                  images: (candidateData["images"] as List).cast<String>(),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.scaffoldBackgroundColor,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(6.w),
                    topRight: Radius.circular(6.w),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 4.h),
                    ProfileInfoSectionWidget(candidateData: candidateData),
                    SizedBox(height: 3.h),
                    InterestTagsWidget(
                      interests:
                          (candidateData["interests"] as List).cast<String>(),
                    ),
                    SizedBox(height: 12.h), // Space for bottom buttons
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: ActionButtonsWidget(
        onPassPressed: _onPassPressed,
        onSendMatchRequest: _onSendMatchRequest,
      ),
    );
  }
}
