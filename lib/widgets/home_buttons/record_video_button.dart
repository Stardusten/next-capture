import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/api_service.dart';
import '../../widgets/toast.dart';

class RecordVideoButton extends StatefulWidget {
  const RecordVideoButton({super.key});

  @override
  State<RecordVideoButton> createState() => _RecordVideoButtonState();
}

class _RecordVideoButtonState extends State<RecordVideoButton> {
  bool _isUploading = false;
  double _progress = 0;

  String _generateDefaultFileName() {
    final now = DateTime.now();
    return 'VID_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
  }

  Future<void> _uploadVideo(File video) async {
    final controller = TextEditingController(text: _generateDefaultFileName());

    final fileName = await showCupertinoDialog<String>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Save Video'),
        content: Padding(
          padding: const EdgeInsets.only(top: 12.0),
          child: CupertinoTextField(
            controller: controller,
            autofocus: true,
            placeholder: 'Enter file name',
            suffix: Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Text(
                '.MP4',
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
        video,
        'video',
        onProgress: (progress) {
          setState(() {
            _progress = progress;
          });
        },
      );

      if (mounted) {
        Toast.show(
          context,
          'Video uploaded successfully',
          ToastType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        Toast.show(
          context,
          'Failed to upload video: $e',
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

  Future<void> _recordVideo() async {
    try {
      final video = await ImagePicker().pickVideo(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        maxDuration: const Duration(minutes: 10),
      );

      if (video != null) {
        await _uploadVideo(File(video.path));
      }
    } catch (e) {
      print('视频录制失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _isUploading ? null : _recordVideo,
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
                'Record Video',
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
                  CupertinoIcons.film,
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
