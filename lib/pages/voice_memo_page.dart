import 'dart:async';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import '../services/api_service.dart';
import '../widgets/toast.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class VoiceMemoPage extends StatefulWidget {
  const VoiceMemoPage({super.key});

  @override
  State<VoiceMemoPage> createState() => _VoiceMemoPageState();
}

class _VoiceMemoPageState extends State<VoiceMemoPage> {
  bool _isUploading = false;
  bool _isRecording = false;
  double _progress = 0;
  final _audioRecorder = AudioRecorder();
  Duration _duration = Duration.zero;
  Timer? _timer;
  String? _currentRecordingPath;
  List<double> _amplitudes = List.filled(13, 20);
  Timer? _amplitudeTimer;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    if (!await _audioRecorder.hasPermission()) {
      if (mounted) {
        Toast.show(
          context,
          'Microphone permission is required',
          ToastType.error,
        );
      }
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _duration += const Duration(seconds: 1);
      });
    });
  }

  void _resetTimer() async {
    if (_isRecording) {
      await _stopRecording();
    }
    _timer?.cancel();
    setState(() {
      _duration = Duration.zero;
      _currentRecordingPath = null;
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String hours = twoDigits(duration.inHours);
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  void _startAmplitudeTimer() {
    _amplitudeTimer?.cancel();
    _amplitudeTimer =
        Timer.periodic(const Duration(milliseconds: 100), (timer) async {
      if (_isRecording) {
        try {
          final amplitude = await _audioRecorder.getAmplitude();
          final normalized = (amplitude.current ?? -160) + 160; // 转换为 0-160 范围
          setState(() {
            // 更新波形图数据
            _amplitudes.removeAt(0);
            _amplitudes.add(20 + (normalized / 160) * 30); // 20-50 范围
          });
        } catch (e) {
          print('获取音量失败: $e');
        }
      }
    });
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final tempDir = await getTemporaryDirectory();
        final path = '${tempDir.path}/temp_recording.m4a';

        await _audioRecorder.start(
          RecordConfig(
            encoder: AudioEncoder.aacLc,
            bitRate: 128000,
            sampleRate: 44100,
          ),
          path: path,
        );

        setState(() {
          _isRecording = true;
        });
        _startTimer();
        _startAmplitudeTimer();
      }
    } catch (e) {
      print('录音失败: $e');
      if (mounted) {
        Toast.show(
          context,
          'Failed to start recording',
          ToastType.error,
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    _timer?.cancel();
    _amplitudeTimer?.cancel();
    try {
      final path = await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
        _currentRecordingPath = path;
      });
    } catch (e) {
      print('停止录音失败: $e');
      if (mounted) {
        Toast.show(
          context,
          'Failed to stop recording',
          ToastType.error,
        );
      }
    }
  }

  Future<void> _submitRecording() async {
    if (_currentRecordingPath == null) return;
    await _uploadAudio(File(_currentRecordingPath!));
    _currentRecordingPath = null;
    _resetTimer();
  }

  Future<void> _uploadAudio(File audio) async {
    final controller = TextEditingController(text: _generateDefaultFileName());

    final fileName = await showCupertinoDialog<String>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Save Recording'),
        content: Padding(
          padding: const EdgeInsets.only(top: 12.0),
          child: CupertinoTextField(
            controller: controller,
            autofocus: true,
            placeholder: 'Enter file name',
            suffix: Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Text(
                '.M4A',
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
        audio,
        'audio',
        onProgress: (progress) {
          setState(() {
            _progress = progress;
          });
        },
      );

      if (mounted) {
        Toast.show(
          context,
          'Recording uploaded successfully',
          ToastType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        Toast.show(
          context,
          'Failed to upload recording: $e',
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

  String _generateDefaultFileName() {
    final now = DateTime.now();
    return 'REC_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _amplitudeTimer?.cancel();
    _audioRecorder.dispose();
    super.dispose();
  }

  Widget _buildWaveform() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        13,
        (index) => TweenAnimationBuilder<double>(
          tween: Tween(begin: 20, end: _amplitudes[index]),
          duration: const Duration(milliseconds: 100),
          builder: (context, value, child) => Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            width: 8,
            height: value,
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey.withOpacity(0.5),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Record  Voice'),
        backgroundColor: CupertinoColors.black,
        border: null,
      ),
      backgroundColor: CupertinoColors.black,
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildWaveform(),
                    const SizedBox(height: 40),
                    // 时间显示
                    Text(
                      _formatDuration(_duration),
                      style: const TextStyle(
                        color: CupertinoColors.white,
                        fontSize: 64,
                        fontWeight: FontWeight.w200,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // 底部控制栏
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Reset 按钮
                  SizedBox(
                    width: 72,
                    height: 72,
                    child: Center(
                      child: CupertinoButton(
                        onPressed: _resetTimer,
                        padding: EdgeInsets.zero,
                        child: const Text(
                          'Reset',
                          style: TextStyle(
                            color: CupertinoColors.white,
                            fontSize: 17,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // 录音按钮
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: CupertinoColors.white,
                        width: 3,
                      ),
                    ),
                    child: Center(
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isRecording
                              ? CupertinoColors.transparent
                              : const Color(0xFFE34234).withOpacity(0.9),
                        ),
                        child: Center(
                          child: Icon(
                            _isRecording
                                ? CupertinoIcons.pause_fill
                                : CupertinoIcons.mic_fill,
                            color: CupertinoColors.white,
                            size: 32,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Send 按钮
                  SizedBox(
                    width: 72,
                    height: 72,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: !_isRecording && _currentRecordingPath != null
                              ? CupertinoColors.systemBlue
                              : CupertinoColors.systemGrey,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          LucideIcons.sendHorizontal,
                          color: CupertinoColors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
