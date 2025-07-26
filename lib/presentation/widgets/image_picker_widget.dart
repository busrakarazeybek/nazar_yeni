import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/app_export.dart';
import '../../services/image_upload_service.dart';

class ImagePickerWidget extends StatefulWidget {
  final String? currentImageUrl;
  final Function(String imageUrl) onImageSelected;
  final String? userId;
  final String bucketType; // 'profile', 'gallery', 'chat'
  final double? width;
  final double? height;
  final bool showEditIcon;
  final String placeholder;
  final bool allowMultiple;
  final Function(List<String> imageUrls)? onMultipleImagesSelected;

  const ImagePickerWidget({
    super.key,
    this.currentImageUrl,
    required this.onImageSelected,
    this.userId,
    this.bucketType = 'profile',
    this.width,
    this.height,
    this.showEditIcon = true,
    this.placeholder = 'Resim Seç',
    this.allowMultiple = false,
    this.onMultipleImagesSelected,
  });

  @override
  State<ImagePickerWidget> createState() => _ImagePickerWidgetState();
}

class _ImagePickerWidgetState extends State<ImagePickerWidget> {
  final ImageUploadService _imageUploadService = ImageUploadService();
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width ?? 30.w,
      height: widget.height ?? 30.w,
      child: Stack(
        children: [
          _buildImageDisplay(),
          if (widget.showEditIcon && !_isUploading) _buildEditButton(),
          if (_isUploading) _buildUploadProgress(),
        ],
      ),
    );
  }

  Widget _buildImageDisplay() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.grey[300]!,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(
        child: widget.currentImageUrl != null && widget.currentImageUrl!.isNotEmpty
            ? CustomImageWidget(
                imageUrl: widget.currentImageUrl!,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
              )
            : Container(
                color: Colors.grey[100],
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_a_photo,
                      size: 8.w,
                      color: Colors.grey[500],
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      widget.placeholder,
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildEditButton() {
    return Positioned(
      bottom: 0,
      right: 0,
      child: GestureDetector(
        onTap: _showImagePicker,
        child: Container(
          width: 8.w,
          height: 8.w,
          decoration: BoxDecoration(
            color: AppTheme.lightTheme.primaryColor,
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.lightTheme.primaryColor.withOpacity(0.3),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            Icons.edit,
            color: Colors.white,
            size: 4.w,
          ),
        ),
      ),
    );
  }

  Widget _buildUploadProgress() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black.withOpacity(0.5),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 12.w,
              height: 12.w,
              child: CircularProgressIndicator(
                value: _uploadProgress,
                strokeWidth: 3,
                backgroundColor: Colors.white.withOpacity(0.3),
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              '${(_uploadProgress * 100).toInt()}%',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showImagePicker() async {
    if (widget.allowMultiple) {
      await _pickMultipleImages();
    } else {
      final source = await _imageUploadService.showImageSourceDialog(context);
      if (source != null) {
        await _pickAndUploadImage(source);
      }
    }
  }

  Future<void> _pickAndUploadImage(ImageSource source) async {
    try {
      setState(() {
        _isUploading = true;
        _uploadProgress = 0.0;
      });

      // Pick image
      final pickedFile = await _imageUploadService.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile == null) {
        setState(() {
          _isUploading = false;
        });
        return;
      }

      // Validate image
      await _imageUploadService.validateImage(pickedFile);

      // Upload image based on bucket type
      String imageUrl;
      
      if (widget.userId == null) {
        throw Exception('Kullanıcı ID gerekli');
      }

      switch (widget.bucketType) {
        case 'profile':
          imageUrl = await _imageUploadService.uploadProfileImage(
            imageFile: pickedFile,
            userId: widget.userId!,
            onProgress: (progress) {
              setState(() {
                _uploadProgress = progress;
              });
            },
          );
          break;
        case 'gallery':
          imageUrl = await _imageUploadService.uploadGalleryImage(
            imageFile: pickedFile,
            userId: widget.userId!,
            onProgress: (progress) {
              setState(() {
                _uploadProgress = progress;
              });
            },
          );
          break;
        case 'chat':
          imageUrl = await _imageUploadService.uploadChatImage(
            imageFile: pickedFile,
            userId: widget.userId!,
            chatId: 'default', // You might want to pass actual chat ID
            onProgress: (progress) {
              setState(() {
                _uploadProgress = progress;
              });
            },
          );
          break;
        default:
          throw Exception('Bilinmeyen bucket türü: ${widget.bucketType}');
      }

      // Update profile image in database if it's a profile image
      if (widget.bucketType == 'profile') {
        await _imageUploadService.updateUserProfileImage(
          userId: widget.userId!,
          imageUrl: imageUrl,
        );
      }

      widget.onImageSelected(imageUrl);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Resim başarıyla yüklendi'),
            backgroundColor: Colors.green,
          ),
        );
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadProgress = 0.0;
        });
      }
    }
  }

  Future<void> _pickMultipleImages() async {
    try {
      setState(() {
        _isUploading = true;
        _uploadProgress = 0.0;
      });

      // Pick multiple images
      final pickedFiles = await _imageUploadService.pickMultipleImages(
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
        limit: 5, // Limit to 5 images
      );

      if (pickedFiles == null || pickedFiles.isEmpty) {
        setState(() {
          _isUploading = false;
        });
        return;
      }

      if (widget.userId == null) {
        throw Exception('Kullanıcı ID gerekli');
      }

      // Upload multiple images
      final imageUrls = await _imageUploadService.uploadMultipleGalleryImages(
        imageFiles: pickedFiles,
        userId: widget.userId!,
        onProgress: (progress) {
          setState(() {
            _uploadProgress = progress;
          });
        },
      );

      if (widget.onMultipleImagesSelected != null) {
        widget.onMultipleImagesSelected!(imageUrls);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${imageUrls.length} resim başarıyla yüklendi'),
            backgroundColor: Colors.green,
          ),
        );
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadProgress = 0.0;
        });
      }
    }
  }
}

class ImageGalleryWidget extends StatefulWidget {
  final String userId;
  final bool isEditable;
  final int maxImages;

  const ImageGalleryWidget({
    super.key,
    required this.userId,
    this.isEditable = true,
    this.maxImages = 6,
  });

  @override
  State<ImageGalleryWidget> createState() => _ImageGalleryWidgetState();
}

class _ImageGalleryWidgetState extends State<ImageGalleryWidget> {
  final ImageUploadService _imageUploadService = ImageUploadService();
  List<Map<String, dynamic>> _galleryImages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGalleryImages();
  }

  Future<void> _loadGalleryImages() async {
    try {
      final images = await _imageUploadService.getUserGallery(widget.userId);
      setState(() {
        _galleryImages = images;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error loading gallery images: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Fotoğraf Galerisi',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (widget.isEditable && _galleryImages.length < widget.maxImages)
              TextButton.icon(
                onPressed: _addImages,
                icon: Icon(Icons.add_photo_alternate),
                label: Text('Ekle'),
              ),
          ],
        ),
        SizedBox(height: 2.h),
        _buildImageGrid(),
      ],
    );
  }

  Widget _buildImageGrid() {
    if (_galleryImages.isEmpty) {
      return Container(
        height: 20.h,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.photo_library_outlined,
                size: 12.w,
                color: Colors.grey[400],
              ),
              SizedBox(height: 1.h),
              Text(
                'Henüz fotoğraf eklenmemiş',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12.sp,
                ),
              ),
              if (widget.isEditable) ...[
                SizedBox(height: 1.h),
                ElevatedButton.icon(
                  onPressed: _addImages,
                  icon: Icon(Icons.add_photo_alternate),
                  label: Text('Fotoğraf Ekle'),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2.w,
        mainAxisSpacing: 2.w,
        childAspectRatio: 1,
      ),
      itemCount: _galleryImages.length,
      itemBuilder: (context, index) {
        final image = _galleryImages[index];
        return _buildImageItem(image, index);
      },
    );
  }

  Widget _buildImageItem(Map<String, dynamic> image, int index) {
    return GestureDetector(
      onTap: () => _showImageFullScreen(image['image_url']),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CustomImageWidget(
                imageUrl: image['image_url'],
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ),
          if (widget.isEditable)
            Positioned(
              top: 1.w,
              right: 1.w,
              child: GestureDetector(
                onTap: () => _deleteImage(image['id'], index),
                child: Container(
                  width: 6.w,
                  height: 6.w,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 4.w,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _addImages() async {
    try {
      final pickedFiles = await _imageUploadService.pickMultipleImages(
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
        limit: widget.maxImages - _galleryImages.length,
      );

      if (pickedFiles == null || pickedFiles.isEmpty) return;

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 2.h),
              Text('Fotoğraflar yükleniyor...'),
            ],
          ),
        ),
      );

      final imageUrls = await _imageUploadService.uploadMultipleGalleryImages(
        imageFiles: pickedFiles,
        userId: widget.userId,
      );

      // Add to gallery
      for (final imageUrl in imageUrls) {
        await _imageUploadService.addToUserGallery(
          userId: widget.userId,
          imageUrl: imageUrl,
        );
      }

      Navigator.of(context).pop(); // Close loading dialog
      await _loadGalleryImages(); // Reload gallery

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${imageUrls.length} fotoğraf eklendi'),
          backgroundColor: Colors.green,
        ),
      );

    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog if open
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteImage(String imageId, int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Fotoğrafı Sil'),
        content: Text('Bu fotoğrafı silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Sil', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _imageUploadService.removeFromUserGallery(
          userId: widget.userId,
          imageId: imageId,
        );

        setState(() {
          _galleryImages.removeAt(index);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fotoğraf silindi'),
            backgroundColor: Colors.green,
          ),
        );

      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showImageFullScreen(String imageUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            iconTheme: IconThemeData(color: Colors.white),
          ),
          body: Center(
            child: InteractiveViewer(
              child: CustomImageWidget(
                imageUrl: imageUrl,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }
}