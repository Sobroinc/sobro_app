import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/config.dart';

/// Photo picker widget for selecting and displaying product photos.
/// Supports camera capture and gallery selection.
class PhotoPicker extends StatelessWidget {
  /// List of photo URLs or local file paths
  final List<String> photos;

  /// Callback when photos list changes
  final ValueChanged<List<String>> onPhotosChanged;

  /// Optional: callback when a new photo is picked (for upload handling)
  final Future<String?> Function(String localPath)? onPhotoPicked;

  const PhotoPicker({
    super.key,
    required this.photos,
    required this.onPhotosChanged,
    this.onPhotoPicked,
  });

  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    if (photos.length >= AppConfig.maxPhotoCount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Maximum ${AppConfig.maxPhotoCount} photos allowed'),
        ),
      );
      return;
    }

    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: source,
      imageQuality: AppConfig.imageQuality,
      maxWidth: AppConfig.maxImageDimension.toDouble(),
      maxHeight: AppConfig.maxImageDimension.toDouble(),
    );

    if (image != null && context.mounted) {
      if (onPhotoPicked != null) {
        // Upload and get URL
        final url = await onPhotoPicked!(image.path);
        if (url != null) {
          onPhotosChanged([...photos, url]);
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to upload photo')),
            );
          }
        }
      } else {
        // Just add local path (for preview before upload)
        onPhotosChanged([...photos, image.path]);
      }
    }
  }

  void _removePhoto(int index) {
    final newPhotos = [...photos];
    newPhotos.removeAt(index);
    onPhotosChanged(newPhotos);
  }

  void _showPickerOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(context, ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(context, ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Photos', style: Theme.of(context).textTheme.titleMedium),
            Text(
              '${photos.length}/${AppConfig.maxPhotoCount}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              // Add button
              _AddPhotoButton(onTap: () => _showPickerOptions(context)),
              const SizedBox(width: 12),

              // Photos
              ...photos.asMap().entries.map((entry) {
                final index = entry.key;
                final photo = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: _PhotoTile(
                    photoPath: photo,
                    onRemove: () => _removePhoto(index),
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}

class _AddPhotoButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AddPhotoButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_a_photo,
              size: 32,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 8),
            const Text('Add Photo'),
          ],
        ),
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  final String photoPath;
  final VoidCallback onRemove;

  const _PhotoTile({required this.photoPath, required this.onRemove});

  bool get isLocalFile =>
      photoPath.startsWith('/') || photoPath.startsWith('file://');

  bool get isNetworkUrl =>
      photoPath.startsWith('http://') || photoPath.startsWith('https://');

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(width: 120, height: 120, child: _buildImage()),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 16, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImage() {
    if (isNetworkUrl) {
      return CachedNetworkImage(
        imageUrl: photoPath,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: Colors.grey.shade200,
          child: const Center(child: CircularProgressIndicator()),
        ),
        errorWidget: (context, url, error) => Container(
          color: Colors.grey.shade200,
          child: const Icon(Icons.error),
        ),
      );
    } else if (isLocalFile) {
      final file = File(photoPath.replaceFirst('file://', ''));
      return Image.file(
        file,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: Colors.grey.shade200,
          child: const Icon(Icons.error),
        ),
      );
    } else {
      // Relative path - assume it's a network URL with base
      return CachedNetworkImage(
        imageUrl: '${AppConfig.baseUrl}/$photoPath',
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: Colors.grey.shade200,
          child: const Center(child: CircularProgressIndicator()),
        ),
        errorWidget: (context, url, error) => Container(
          color: Colors.grey.shade200,
          child: const Icon(Icons.error),
        ),
      );
    }
  }
}
