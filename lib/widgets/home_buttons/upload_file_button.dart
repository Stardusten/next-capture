import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/api_service.dart';
import '../../widgets/toast.dart';

class UploadFileButton extends StatefulWidget {
  const UploadFileButton({super.key});

  @override
  State<UploadFileButton> createState() => _UploadFileButtonState();
}

class _UploadFileButtonState extends State<UploadFileButton> {
  bool _isUploading = false;
  double _progress = 0;

  Future<void> _uploadFile(File file) async {
    // 检查文件类型
    final extension = file.path.split('.').last.toLowerCase();
    final isImage =
        ['jpg', 'jpeg', 'png', 'gif', 'webp', 'heic'].contains(extension);
    final isVideo = ['mp4', 'mov', 'avi', 'mkv', 'wmv'].contains(extension);
    final isAudio = ['mp3', 'wav', 'm4a', 'aac', 'ogg'].contains(extension);

    final apiService = ApiService();
    String targetPath = apiService.fileUploadPath;

    if (isImage || isVideo || isAudio) {
      final suggestedPath = isImage
          ? apiService.imageUploadPath
          : isVideo
              ? apiService.videoUploadPath
              : apiService.audioUploadPath;

      final result = await showCupertinoDialog<String>(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: Text('Upload to $suggestedPath?'),
          content: Text(
              'Do you want to upload this ${isImage ? 'image' : isVideo ? 'video' : 'audio'} to $suggestedPath?'),
          actions: [
            CupertinoDialogAction(
              child: Text('Upload to "${apiService.fileUploadPath}"'),
              onPressed: () => Navigator.pop(context, 'files'),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              child: Text('Upload to "${suggestedPath}"'),
              onPressed: () => Navigator.pop(context, 'suggested'),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              child: const Text('Cancel'),
              onPressed: () => Navigator.pop(context, 'cancel'),
            ),
          ],
        ),
      );

      if (result == 'cancel') {
        return;
      } else if (result == 'suggested') {
        targetPath = suggestedPath;
      }
    }

    setState(() {
      _isUploading = true;
      _progress = 0;
    });

    try {
      await ApiService().uploadFile(
        file,
        targetPath,
        onProgress: (progress) {
          setState(() {
            _progress = progress;
          });
        },
      );

      if (mounted) {
        Toast.show(
          context,
          'File uploaded successfully',
          ToastType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        Toast.show(
          context,
          'Failed to upload file: $e',
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

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result != null) {
        final file = File(result.files.first.path!);
        await _uploadFile(file);
      }
    } catch (e) {
      print('选择文件失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _isUploading ? null : _pickFile,
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
                'Upload File',
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
                  CupertinoIcons.doc,
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
