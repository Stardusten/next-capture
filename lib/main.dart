import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_demo/services/api_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import 'pages/user_profile_page.dart';
import 'pages/history_page.dart';
import 'pages/splash_page.dart';
import 'pages/login_page.dart';
import 'widgets/home_buttons/upload_file_button.dart';
import 'widgets/home_buttons/record_voice_button.dart';
import 'widgets/home_buttons/take_photo_button.dart';
import 'widgets/home_buttons/record_video_button.dart';
import 'widgets/home_buttons/take_note_button.dart';
import 'widgets/toast.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 添加日志过滤
  debugPrint = (String? message, {int? wrapWidth}) {
    if (message?.contains('MESA') ?? false) return;
    print(message);
  };

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      title: 'Next Capture',
      theme: const CupertinoThemeData(
        brightness: Brightness.dark,
        primaryColor: CupertinoColors.systemBlue,
        scaffoldBackgroundColor: CupertinoColors.black,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashPage(),
        '/login': (context) => const LoginPage(),
        '/home': (context) => const MyHomePage(title: 'Next Capture'),
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

enum SyncStatus { synced, syncing, offline }

class _MyHomePageState extends State<MyHomePage> {
  final ImagePicker _picker = ImagePicker();
  StreamSubscription? _intentDataStreamSubscription;

  // 当前同步状态（后续可以根据实际同步逻辑更新）
  SyncStatus _syncStatus = SyncStatus.synced;

  // 获取状态对应的颜色
  Color _getSyncStatusColor() {
    switch (_syncStatus) {
      case SyncStatus.synced:
        return CupertinoColors.systemGreen;
      case SyncStatus.syncing:
        return CupertinoColors.systemBlue;
      case SyncStatus.offline:
        return CupertinoColors.systemOrange;
    }
  }

  // 获取状态对应的文字
  String _getSyncStatusText() {
    switch (_syncStatus) {
      case SyncStatus.synced:
        return 'All synced';
      case SyncStatus.syncing:
        return 'Syncing...';
      case SyncStatus.offline:
        return 'Offline';
    }
  }

  Future<void> _takePicture() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (photo != null) {
        if (mounted) {
          // 这里可以处理拍摄的照片，比如显示预览或上传
          print('照片保存在: ${photo.path}');
        }
      }
    } catch (e) {
      print('拍照失败: $e');
    }
  }

  Future<void> _takeVideo() async {
    try {
      final XFile? video = await _picker.pickVideo(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        maxDuration: const Duration(minutes: 10), // 设置最大录制时长
      );

      if (video != null) {
        if (mounted) {
          // 这里可以处理录制的视频，比如显示预览或上传
          print('视频保存在: ${video.path}');
        }
      }
    } catch (e) {
      print('视频录制失败: $e');
    }
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any, // 允许选择任何类型的文件
        allowMultiple: false, // 单选模式
      );

      if (result != null) {
        PlatformFile file = result.files.first;
        if (mounted) {
          print('选择的文件: ${file.name}');
          print('文件路径: ${file.path}');
          print('文件大小: ${file.size} bytes');
        }
      }
    } catch (e) {
      print('选择文件失败: $e');
    }
  }

  @override
  void initState() {
    super.initState();

    // 监听分享事件
    _intentDataStreamSubscription = ReceiveSharingIntent.instance
        .getMediaStream()
        .listen((List<SharedMediaFile> value) {
      if (value.isNotEmpty) {
        _handleSharedFiles(value);
      }
    }, onError: (err) {
      print("getMediaStream error: $err");
    });

    // 检查是否有通过分享启动应用
    ReceiveSharingIntent.instance.getInitialMedia().then((value) {
      if (value.isNotEmpty) {
        _handleSharedFiles(value);
        // 告诉库我们已经处理完这个 intent
        ReceiveSharingIntent.instance.reset();
      }
    });
  }

  @override
  void dispose() {
    _intentDataStreamSubscription?.cancel();
    super.dispose();
  }

  Future<void> _handleSharedFiles(List<SharedMediaFile> files) async {
    // 如果未登录，先导航到登录页面
    if (!ApiService().isLoggedIn) {
      if (mounted) {
        await Navigator.pushNamed(context, '/login');
      }
      if (!ApiService().isLoggedIn) return; // 如果用户没有登录，直接返回
    }

    // 上传所有分享的文件
    for (final file in files) {
      final path = file.path;
      if (path == null) continue;

      try {
        // 根据文件类型选择上传路径
        final type = switch (file.type) {
          SharedMediaType.image => 'image',
          SharedMediaType.video => 'video',
          SharedMediaType.file => 'file',
          _ => 'file',
        };

        await ApiService().uploadFile(
          File(path),
          type,
          overwrite: ApiService().overwriteFiles,
          mkdir: ApiService().createDirectories,
          onProgress: (progress) {
            // TODO: 显示上传进度
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
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Next Capture',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        backgroundColor: CupertinoColors.black,
        border: null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 同步状态指示器
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  CupertinoPageRoute(
                    builder: (context) => const HistoryPage(),
                  ),
                );
              },
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _getSyncStatusColor(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _getSyncStatusText(),
                    style: const TextStyle(
                      color: CupertinoColors.systemGrey,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // 用户头像
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  CupertinoPageRoute(
                    builder: (context) => const UserProfilePage(),
                  ),
                );
              },
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: CupertinoColors.systemGrey,
                  image: const DecorationImage(
                    image: AssetImage('assets/avatar.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      backgroundColor: CupertinoColors.black,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Center(
                child: SizedBox(
                  width: 500,
                  child: GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.5,
                    children: const [
                      UploadFileButton(),
                      RecordVoiceButton(),
                      TakePhotoButton(),
                      RecordVideoButton(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Center(
                child: SizedBox(
                  width: 500,
                  child: TakeNoteButton(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
