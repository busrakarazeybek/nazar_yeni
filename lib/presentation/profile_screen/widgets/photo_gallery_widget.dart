import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../../core/app_export.dart';

class PhotoGalleryWidget extends StatefulWidget {
  final List<String> profileImages;
  final Function(List<String>) onImagesChanged;

  const PhotoGalleryWidget({
    super.key,
    required this.profileImages,
    required this.onImagesChanged,
  });

  @override
  State<PhotoGalleryWidget> createState() => _PhotoGalleryWidgetState();
}

class _PhotoGalleryWidgetState extends State<PhotoGalleryWidget> {
  List<String> _images = [];

  @override
  void initState() {
    super.initState();
    _images = List.from(widget.profileImages);
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      print("_pickImage called with source: $source");
      if (_images.length >= 6) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Maksimum 6 fotoğraf ekleyebilirsiniz'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final ImagePicker picker = ImagePicker();
      print("ImagePicker created, attempting to pick image...");
      
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );
      
      print("Image picker result: ${image?.path}");
      
      if (image != null) {
        print("Image selected: ${image.path}");
        setState(() {
          _images.add(image.path);
        });
        widget.onImagesChanged(_images);
        HapticFeedback.selectionClick();
        print("Image added to list. Total images: ${_images.length}");
      } else {
        print("No image selected");
      }
    } catch (e) {
      print("Error in _pickImage: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fotoğraf seçilemedi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
    widget.onImagesChanged(_images);
    HapticFeedback.selectionClick();
  }

  void _reorderImages(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final String item = _images.removeAt(oldIndex);
      _images.insert(newIndex, item);
    });
    widget.onImagesChanged(_images);
    HapticFeedback.selectionClick();
  }

  void _showImagePickerBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.lightTheme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 3.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12.w,
              height: 0.5.h,
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.outline.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              'Fotoğraf Ekle',
              style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 3.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildImageSourceOption(
                  context: context,
                  icon: Icons.camera_alt,
                  label: 'Kamera',
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                _buildImageSourceOption(
                  context: context,
                  icon: Icons.photo_library,
                  label: 'Galeri',
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSourceOption({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
            Icon(
              icon,
              color: AppTheme.lightTheme.primaryColor,
              size: 32,
            ),
            SizedBox(height: 1.h),
            Text(
              label,
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: AppTheme.lightTheme.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                iconName: 'photo_library',
                color: AppTheme.lightTheme.primaryColor,
                size: 24,
              ),
              SizedBox(width: 2.w),
              Text(
                'Fotoğraf Galerisi',
                style: AppTheme.lightTheme.textTheme.titleMedium,
              ),
              Spacer(),
              Text(
                '${_images.length}/6',
                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  color: _images.length >= 3 
                      ? AppTheme.successColor 
                      : AppTheme.errorColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          
          if (_images.isEmpty) ...[
            Container(
              height: 20.h,
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.lightTheme.colorScheme.outline.withOpacity(0.3),
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_photo_alternate_outlined,
                      size: 48,
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      'Henüz fotoğraf eklenmemiş',
                      style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    SizedBox(height: 1.h),
                    ElevatedButton.icon(
                      onPressed: _showImagePickerBottomSheet,
                      icon: Icon(Icons.add),
                      label: Text('Fotoğraf Ekle'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.lightTheme.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            ReorderableGridView.count(
              crossAxisCount: 3,
              crossAxisSpacing: 2.w,
              mainAxisSpacing: 1.h,
              childAspectRatio: 1,
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              onReorder: _reorderImages,
              children: [
                ..._images.asMap().entries.map((entry) {
                  final index = entry.key;
                  final imagePath = entry.value;
                  return _buildImageTile(imagePath, index);
                }),
                if (_images.length < 6)
                  _buildAddImageTile(),
              ],
            ),
            SizedBox(height: 2.h),
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.lightTheme.primaryColor.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppTheme.lightTheme.primaryColor,
                    size: 20,
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      'İlk fotoğraf ana profil fotoğrafınız olacak. Fotoğrafları sürükleyerek sıralayabilirsiniz.',
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.lightTheme.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildImageTile(String imagePath, int index) {
    final isMainPhoto = index == 0;
    
    return Container(
      key: ValueKey(imagePath),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isMainPhoto 
                    ? AppTheme.lightTheme.primaryColor 
                    : AppTheme.lightTheme.colorScheme.outline.withOpacity(0.3),
                width: isMainPhoto ? 2 : 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _buildImageWidget(imagePath),
            ),
          ),
          if (isMainPhoto)
            Positioned(
              bottom: 5,
              left: 5,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.primaryColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Ana',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          Positioned(
            top: 5,
            right: 5,
            child: GestureDetector(
              onTap: () => _removeImage(index),
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: AppTheme.errorColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddImageTile() {
    return Container(
      key: ValueKey('add_image'),
      child: GestureDetector(
        onTap: _showImagePickerBottomSheet,
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.lightTheme.colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.lightTheme.colorScheme.outline.withOpacity(0.3),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_photo_alternate_outlined,
                color: AppTheme.lightTheme.primaryColor,
                size: 32,
              ),
              SizedBox(height: 1.h),
              Text(
                'Ekle',
                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.lightTheme.primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageWidget(String imagePath) {
    if (imagePath.startsWith('http')) {
      // Network image
      return Image.network(
        imagePath,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) => Container(
          color: Colors.grey[300],
          child: Icon(Icons.error, color: Colors.grey[600]),
        ),
      );
    } else {
      // Local file
      return Image.file(
        File(imagePath),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) => Container(
          color: Colors.grey[300],
          child: Icon(Icons.error, color: Colors.grey[600]),
        ),
      );
    }
  }
}

class ReorderableGridView extends StatelessWidget {
  final int crossAxisCount;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final double childAspectRatio;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final ReorderCallback onReorder;
  final List<Widget> children;

  const ReorderableGridView.count({
    super.key,
    required this.crossAxisCount,
    this.crossAxisSpacing = 0.0,
    this.mainAxisSpacing = 0.0,
    this.childAspectRatio = 1.0,
    this.shrinkWrap = false,
    this.physics,
    required this.onReorder,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return ReorderableListView.builder(
      shrinkWrap: shrinkWrap,
      physics: physics,
      onReorder: onReorder,
      itemCount: (children.length / crossAxisCount).ceil(),
      itemBuilder: (context, rowIndex) {
        final startIndex = rowIndex * crossAxisCount;
        final endIndex = (startIndex + crossAxisCount).clamp(0, children.length);
        final rowChildren = children.sublist(startIndex, endIndex);
        
        return Container(
          key: ValueKey('row_$rowIndex'),
          margin: EdgeInsets.only(bottom: mainAxisSpacing),
          child: Row(
            children: [
              for (int i = 0; i < rowChildren.length; i++) ...[
                Expanded(child: rowChildren[i]),
                if (i < rowChildren.length - 1) SizedBox(width: crossAxisSpacing),
              ],
              // Fill remaining space if row is not complete
              for (int i = rowChildren.length; i < crossAxisCount; i++) ...[
                if (i > 0) SizedBox(width: crossAxisSpacing),
                Expanded(child: Container()),
              ],
            ],
          ),
        );
      },
    );
  }
}