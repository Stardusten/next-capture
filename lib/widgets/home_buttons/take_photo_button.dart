import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/api_service.dart';
import '../../widgets/toast.dart';

class TakePhotoButton extends StatefulWidget {
  const TakePhotoButton({super.key});

  @override
  State<TakePhotoButton> createState() => _TakePhotoButtonState();
}

class _TakePhotoButtonState extends State<TakePhotoButton> {
  bool _isUploading = false;
  double _progress = 0;

  String _generateDefaultFileName() {
    final now = DateTime.now();
    return 'IMG_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
  }

  Future<void> _uploadPhoto(File photo) async {
    final controller = TextEditingController(text: _generateDefaultFileName());

    final fileName = await showCupertinoDialog<String>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Save Photo'),
        content: Padding(
          padding: const EdgeInsets.only(top: 12.0),
          child: CupertinoTextField(
            controller: controller,
            autofocus: true,
            placeholder: 'Enter file name',
            suffix: Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Text(
                '.JPG',
                style: TextStyle(
                  color: CupertinoColors.systemGrey.withOpacity(0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('Save'),
            onPressed: () => Navigator.pop(context, controller.text),
          ),
        ],
      ),
    );

    if (fileName == null || fileName.isEmpty) return;

    setState(() {
      _isUploading = true;
      _progress = 0;
    });

    try {
      await ApiService().uploadFile(
        photo,
        'image',
        onProgress: (progress) {
          setState(() {
            _progress = progress;
          });
        },
      );

      if (mounted) {
        Toast.show(
          context,
          'Photo uploaded successfully',
          ToastType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        Toast.show(
          context,
          'Failed to upload photo: $e',
          ToastType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _progress = 0;
        });
      }
    }
  }

  Future<void> _takePicture() async {
    try {
      final photo = await ImagePicker().pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (photo != null) {
        await _uploadPhoto(File(photo.path));
      }
    } catch (e) {
      print('拍照失败: $e');
    }
  }

  Future<void> _scanDocument() async {
    try {
      final photo = await ImagePicker().pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: 100,
        // TODO: 添加文档扫描相关参数
      );

      if (photo != null) {
        await _uploadPhoto(File(photo.path));
      }
    } catch (e) {
      print('扫描失败: $e');
    }
  }

  void _showContextMenu() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _scanDocument();
            },
            child: const Text('Scan Document'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDestructiveAction: true,
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _isUploading ? null : () => _takePicture(),
      onLongPress: _isUploading ? null : _showContextMenu,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            const Align(
              alignment: Alignment.topLeft,
              child: Text(
                'Take Photo',
                style: TextStyle(
                  color: CupertinoColors.white,
                  fontSize: 16,
                ),
              ),
            ),
            if (_isUploading)
              Align(
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CupertinoActivityIndicator(),
                    const SizedBox(height: 8),
                    Text(
                      '${(_progress * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(
                        color: CupertinoColors.white,
                      ),
                    ),
                  ],
                ),
              )
            else
              const Align(
                alignment: Alignment.bottomLeft,
                child: Icon(
                  CupertinoIcons.camera,
                  size: 24,
                  color: CupertinoColors.white,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
