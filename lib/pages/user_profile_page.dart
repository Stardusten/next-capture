import 'package:flutter/cupertino.dart';
import '../services/api_service.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final _apiService = ApiService();
  final _filePathController = TextEditingController();
  final _imagePathController = TextEditingController();
  final _videoPathController = TextEditingController();
  final _audioPathController = TextEditingController();
  bool _overwriteFiles = false;
  bool _createDirectories = false;

  @override
  void initState() {
    super.initState();
    _filePathController.text = _apiService.fileUploadPath;
    _imagePathController.text = _apiService.imageUploadPath;
    _videoPathController.text = _apiService.videoUploadPath;
    _audioPathController.text = _apiService.audioUploadPath;
    _overwriteFiles = _apiService.overwriteFiles;
    _createDirectories = _apiService.createDirectories;
  }

  @override
  void dispose() {
    _filePathController.dispose();
    _imagePathController.dispose();
    _videoPathController.dispose();
    _audioPathController.dispose();
    super.dispose();
  }

  Future<void> _updatePaths() async {
    await _apiService.updateUploadPaths(
      fileUploadPath: _filePathController.text,
      imageUploadPath: _imagePathController.text,
      videoUploadPath: _videoPathController.text,
      audioUploadPath: _audioPathController.text,
    );
  }

  Future<void> _updateSettings(
      {bool? overwriteFiles, bool? createDirectories}) async {
    await _apiService.updateUploadSettings(
      overwriteFiles: overwriteFiles,
      createDirectories: createDirectories,
    );
  }

  Widget _buildPathInput(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: CupertinoColors.systemGrey,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        CupertinoTextField(
          controller: controller,
          onChanged: (_) => _updatePaths(),
          style: const TextStyle(color: CupertinoColors.white),
          decoration: BoxDecoration(
            color: const Color(0xFF2C2C2E),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(12),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Profile'),
        backgroundColor: CupertinoColors.black,
        border: null,
      ),
      backgroundColor: CupertinoColors.black,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1C1E),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Server',
                      style: TextStyle(
                        color: CupertinoColors.systemGrey,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _apiService.serverUrl ?? '',
                      style: const TextStyle(
                        color: CupertinoColors.white,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Knowledge Base',
                      style: TextStyle(
                        color: CupertinoColors.systemGrey,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _apiService.knowledgeBaseName ?? '',
                      style: const TextStyle(
                        color: CupertinoColors.white,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _apiService.knowledgeBaseLocation ?? '',
                      style: TextStyle(
                        color: CupertinoColors.white.withOpacity(0.6),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1C1E),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Upload Paths',
                          style: TextStyle(
                            color: CupertinoColors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            showCupertinoModalPopup(
                              context: context,
                              builder: (context) => Container(
                                margin: const EdgeInsets.all(20),
                                child: CupertinoPopupSurface(
                                  child: Container(
                                    padding: const EdgeInsets.all(20),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        RichText(
                                          text: TextSpan(
                                            style: const TextStyle(
                                              color: CupertinoColors.white,
                                              fontSize: 16,
                                            ),
                                            children: [
                                              const TextSpan(
                                                text:
                                                    'These paths are relative to the knowledge base attachments directory.\n\n'
                                                    'For example, if your knowledge base is at ',
                                              ),
                                              TextSpan(
                                                text:
                                                    '"${_apiService.knowledgeBaseLocation}"',
                                                style: const TextStyle(
                                                  color: CupertinoColors
                                                      .systemGrey,
                                                  fontFamily: 'Menlo',
                                                ),
                                              ),
                                              const TextSpan(
                                                text:
                                                    ',\nfiles will be uploaded to ',
                                              ),
                                              TextSpan(
                                                text:
                                                    '"${_apiService.knowledgeBaseLocation}/attachments/files"',
                                                style: const TextStyle(
                                                  color: CupertinoColors
                                                      .systemGrey,
                                                  fontFamily: 'Menlo',
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                        CupertinoButton(
                                          child: const Text('OK'),
                                          onPressed: () =>
                                              Navigator.pop(context),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: CupertinoColors.systemGrey,
                                width: 1,
                              ),
                            ),
                            child: const Center(
                              child: Text(
                                '?',
                                style: TextStyle(
                                  color: CupertinoColors.systemGrey,
                                  fontSize: 14,
                                  height: 1.1,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildPathInput('Files', _filePathController),
                    _buildPathInput('Images', _imagePathController),
                    _buildPathInput('Videos', _videoPathController),
                    _buildPathInput('Audios', _audioPathController),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1C1E),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Upload Settings',
                          style: TextStyle(
                            color: CupertinoColors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Overwrite existing files',
                            style: TextStyle(
                              color: CupertinoColors.white.withOpacity(0.9),
                              fontSize: 16,
                            ),
                          ),
                        ),
                        Transform.scale(
                          scale: 0.8,
                          child: CupertinoSwitch(
                            value: _overwriteFiles,
                            onChanged: (value) {
                              setState(() {
                                _overwriteFiles = value;
                              });
                              _updateSettings(overwriteFiles: value);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Create directories if needed',
                            style: TextStyle(
                              color: CupertinoColors.white.withOpacity(0.9),
                              fontSize: 16,
                            ),
                          ),
                        ),
                        Transform.scale(
                          scale: 0.8,
                          child: CupertinoSwitch(
                            value: _createDirectories,
                            onChanged: (value) {
                              setState(() {
                                _createDirectories = value;
                              });
                              _updateSettings(createDirectories: value);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              CupertinoButton.filled(
                onPressed: () => _logout(context),
                child: const Text('Logout'),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    await _apiService.logout();
    if (context.mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }
}
