import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/knowledge_base.dart';
import '../models/response.dart';

class ApiService {
  static const String _tokenKey = 'token';
  static const String _serverUrlKey = 'serverUrl';
  static const String _knowledgeBaseLocationKey = 'knowledgeBaseLocation';
  static const String _knowledgeBaseNameKey = 'knowledgeBaseName';
  static const String _fileUploadPathKey = 'fileUploadPath';
  static const String _imageUploadPathKey = 'imageUploadPath';
  static const String _videoUploadPathKey = 'videoUploadPath';
  static const String _audioUploadPathKey = 'audioUploadPath';
  static const String _overwriteFilesKey = 'overwriteFiles';
  static const String _createDirectoriesKey = 'createDirectories';

  String? _serverUrl;
  String? _token;
  String? _knowledgeBaseLocation;
  String? _knowledgeBaseName;
  List<KnowledgeBase> _knowledgeBases = [];
  String _fileUploadPath = 'files';
  String _imageUploadPath = 'images';
  String _videoUploadPath = 'videos';
  String _audioUploadPath = 'audios';
  bool _overwriteFiles = false;
  bool _createDirectories = true;

  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _serverUrl = prefs.getString(_serverUrlKey);
    _token = prefs.getString(_tokenKey);
    _knowledgeBaseLocation = prefs.getString(_knowledgeBaseLocationKey);
    _knowledgeBaseName = prefs.getString(_knowledgeBaseNameKey);
    _fileUploadPath = prefs.getString(_fileUploadPathKey) ?? 'files';
    _imageUploadPath = prefs.getString(_imageUploadPathKey) ?? 'images';
    _videoUploadPath = prefs.getString(_videoUploadPathKey) ?? 'videos';
    _audioUploadPath = prefs.getString(_audioUploadPathKey) ?? 'audios';
    _overwriteFiles = prefs.getBool(_overwriteFilesKey) ?? false;
    _createDirectories = prefs.getBool(_createDirectoriesKey) ?? true;
  }

  // 获取所有知识库信息
  Future<List<KnowledgeBase>> fetchKnowledgeBases(String serverUrl) async {
    try {
      print('Fetching knowledge bases from: $serverUrl');
      final response = await http.post(
        Uri.parse('$serverUrl/kb/list'),
        body: json.encode({}),
        headers: {'Content-Type': 'application/json'},
      );

      print('Knowledge bases response status: ${response.statusCode}');
      print('Knowledge bases response body: ${response.body}');

      final jsonResponse = json.decode(response.body);
      if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
        final List<dynamic> dataList = jsonResponse['data'];
        _knowledgeBases = dataList
            .map((item) => KnowledgeBase.fromJson(item as Map<String, dynamic>))
            .toList();
        return _knowledgeBases;
      } else {
        throw jsonResponse['code'] ?? 'Failed to fetch knowledge bases';
      }
    } catch (e, stackTrace) {
      print('Fetch knowledge bases error: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // 知识库编辑者登录
  Future<void> login(String serverUrl, String location, String password) async {
    try {
      print('Logging in to: $serverUrl');
      final response = await http.post(
        Uri.parse('$serverUrl/login/kb-editor'),
        body: json.encode({
          'serverUrl': serverUrl,
          'location': location,
          'password': password,
        }),
        headers: {'Content-Type': 'application/json'},
      );

      print('Login response status: ${response.statusCode}');
      print('Login response body: ${response.body}');

      final jsonResponse = json.decode(response.body);
      if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
        _token = jsonResponse['data']['token'];
        _serverUrl = serverUrl;
        _knowledgeBaseLocation = location;
        _knowledgeBaseName =
            _knowledgeBases.firstWhere((kb) => kb.location == location).name;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenKey, _token!);
        await prefs.setString(_serverUrlKey, serverUrl);
        await prefs.setString(_knowledgeBaseLocationKey, location);
        await prefs.setString(_knowledgeBaseNameKey, _knowledgeBaseName!);
      } else {
        throw jsonResponse['code'] ?? 'Login failed';
      }
    } catch (e, stackTrace) {
      print('Login error: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<void> logout() async {
    _token = null;
    _serverUrl = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  bool get isLoggedIn => _token != null;
  String? get serverUrl => _serverUrl;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  // 检测服务器连接性
  Future<void> ping(String serverUrl) async {
    try {
      print('Pinging server: $serverUrl');
      final response = await http.post(
        Uri.parse('$serverUrl/ping'),
        body: json.encode({}),
        headers: {'Content-Type': 'application/json'},
      );

      print('Ping response status: ${response.statusCode}');
      print('Ping response body: ${response.body}');

      final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
        json.decode(response.body),
        (json) => json as Map<String, dynamic>,
      );

      if (!apiResponse.success) {
        throw apiResponse.code ?? 'Server is not responding';
      }
    } catch (e, stackTrace) {
      print('Ping error: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  String? get knowledgeBaseName => _knowledgeBaseName;
  String? get knowledgeBaseLocation => _knowledgeBaseLocation;

  String get fileUploadPath => _fileUploadPath;
  String get imageUploadPath => _imageUploadPath;
  String get videoUploadPath => _videoUploadPath;
  String get audioUploadPath => _audioUploadPath;

  Future<void> updateUploadPaths({
    String? fileUploadPath,
    String? imageUploadPath,
    String? videoUploadPath,
    String? audioUploadPath,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (fileUploadPath != null) {
      _fileUploadPath = fileUploadPath;
      await prefs.setString(_fileUploadPathKey, fileUploadPath);
    }
    if (imageUploadPath != null) {
      _imageUploadPath = imageUploadPath;
      await prefs.setString(_imageUploadPathKey, imageUploadPath);
    }
    if (videoUploadPath != null) {
      _videoUploadPath = videoUploadPath;
      await prefs.setString(_videoUploadPathKey, videoUploadPath);
    }
    if (audioUploadPath != null) {
      _audioUploadPath = audioUploadPath;
      await prefs.setString(_audioUploadPathKey, audioUploadPath);
    }
  }

  /// 上传单个文件并显示进度
  /// [file] 要上传的文件
  /// [type] 文件类型，用于确定上传路径
  /// [onProgress] 上传进度回调
  /// [overwrite] 是否覆盖已存在的文件
  /// [mkdir] 是否创建不存在的目录
  Future<void> uploadFile(
    File file,
    String type, {
    void Function(double progress)? onProgress,
    bool overwrite = false,
    bool mkdir = true,
  }) async {
    if (_serverUrl == null) throw 'Server URL not set';
    if (_token == null) throw 'Not logged in';

    try {
      // 根据文件类型确定目标路径
      final basePath = switch (type) {
        'file' => _fileUploadPath,
        'image' => _imageUploadPath,
        'video' => _videoUploadPath,
        'audio' => _audioUploadPath,
        _ => throw 'Invalid file type',
      };

      // 使用文件名和基础路径构建目标路径
      final fileName = file.path.split('/').last;
      final targetPath = '$basePath/$fileName';

      print('Uploading file to: $targetPath');

      // 添加 overwrite 和 mkdir 参数
      final uri = Uri.parse('$_serverUrl/fs/upload').replace(
        queryParameters: {
          'overwrite': overwrite.toString(),
          'mkdir': mkdir.toString(),
        },
      );

      final request = http.MultipartRequest('POST', uri);

      // 添加认证头
      request.headers.addAll({
        'Authorization': _token!,
      });

      // 添加文件路径和文件
      request.fields['targetPath'] = targetPath;

      // 创建带进度的文件流
      final fileStream = http.ByteStream(file.openRead());
      final length = await file.length();

      final multipartFile = http.MultipartFile(
        'file',
        fileStream,
        length,
        filename: fileName,
      );
      request.files.add(multipartFile);

      // 发送请求并监听进度
      final streamedResponse = await request.send();

      // 收集所有数据并计算进度
      final List<int> bytes = [];
      final completer = Completer<void>();

      streamedResponse.stream.listen(
        (List<int> chunk) {
          bytes.addAll(chunk);
          if (onProgress != null) {
            final progress = bytes.length / length;
            onProgress(progress);
          }
        },
        onDone: () => completer.complete(),
        onError: completer.completeError,
        cancelOnError: true,
      );

      // 等待所有数据接收完成
      await completer.future;

      // 解析响应
      final response = http.Response(
        String.fromCharCodes(bytes),
        streamedResponse.statusCode,
        headers: streamedResponse.headers,
        request: request,
      );

      print('Upload response status: ${response.statusCode}');
      print('Upload response body: ${response.body}');

      final jsonResponse = json.decode(response.body);
      if (jsonResponse['success'] != true) {
        final code = jsonResponse['code'];
        switch (code) {
          case 'FILE_EXISTS':
            throw '同一目录下已经存在同名文件';
          case 'DIR_NOT_FOUND':
            throw '目标路径不存在';
          case 'NO_AUTHORIZATION':
            throw '无法访问该路径';
          case 'INVALID_REQUEST':
            throw '目标路径不存在';
          default:
            throw code ?? 'Upload failed';
        }
      }
    } catch (e, stackTrace) {
      print('Upload error: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// 批量上传文件
  /// [files] 文件列表，每项包含目标路径和文件对象
  Future<void> uploadFiles(List<(String, File)> files) async {
    if (_serverUrl == null) throw 'Server URL not set';
    if (_token == null) throw 'Not logged in';

    try {
      print('Uploading ${files.length} files');

      // 创建 multipart request
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_serverUrl/fs/upload'),
      );

      // 添加认证头
      request.headers.addAll({
        'Authorization': 'Bearer $_token',
      });

      // 添加所有文件
      for (final (targetPath, file) in files) {
        request.fields['targetPath'] = targetPath;
        request.files.add(
          await http.MultipartFile.fromPath(
            'file',
            file.path,
          ),
        );
      }

      // 发送请求
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('Upload response status: ${response.statusCode}');
      print('Upload response body: ${response.body}');

      final jsonResponse = json.decode(response.body);
      if (jsonResponse['success'] != true) {
        throw jsonResponse['code'] ?? 'Upload failed';
      }
    } catch (e, stackTrace) {
      print('Upload error: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  bool get overwriteFiles => _overwriteFiles;
  bool get createDirectories => _createDirectories;

  Future<void> updateUploadSettings({
    bool? overwriteFiles,
    bool? createDirectories,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (overwriteFiles != null) {
      _overwriteFiles = overwriteFiles;
      await prefs.setBool(_overwriteFilesKey, overwriteFiles);
    }
    if (createDirectories != null) {
      _createDirectories = createDirectories;
      await prefs.setBool(_createDirectoriesKey, createDirectories);
    }
  }
}
