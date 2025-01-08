import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';
import '../models/knowledge_base.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _serverUrlController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _serverUrlError;
  String? _passwordError;
  List<KnowledgeBase> _knowledgeBases = [];
  KnowledgeBase? _selectedKnowledgeBase;
  final _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _loadSavedServerUrl();
    _passwordController.addListener(() {
      setState(() {
        // 触发重建以更新登录按钮状态
      });
    });
  }

  Future<void> _loadSavedServerUrl() async {
    if (_apiService.serverUrl != null) {
      _serverUrlController.text = _apiService.serverUrl!;
      _fetchKnowledgeBases();
    }
  }

  bool _isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      // 允许 localhost 和 IP 地址
      return uri.hasScheme &&
          (uri.isScheme('http') || uri.isScheme('https')) &&
          (uri.hasAuthority || uri.host.isNotEmpty);
    } catch (e) {
      return false;
    }
  }

  Future<void> _fetchKnowledgeBases() async {
    if (!_isValidUrl(_serverUrlController.text)) {
      setState(() {
        _serverUrlError = 'Invalid server URL';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _serverUrlError = null;
    });

    try {
      // 先进行 ping 测试
      await _apiService.ping(_serverUrlController.text);

      // ping 成功后获取知识库列表
      final knowledgeBases =
          await _apiService.fetchKnowledgeBases(_serverUrlController.text);
      setState(() {
        _knowledgeBases = knowledgeBases;
      });
    } catch (e) {
      setState(() {
        _serverUrlError = 'Could not connect to server';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _login() async {
    if (_selectedKnowledgeBase == null || _passwordController.text.isEmpty) {
      return;
    }

    setState(() {
      _isLoading = true;
      _passwordError = null;
    });

    try {
      await _apiService.login(
        _serverUrlController.text,
        _selectedKnowledgeBase!.location,
        _passwordController.text,
      );

      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      setState(() {
        _passwordError = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _serverUrlController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.black,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Next Capture',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: CupertinoColors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              // 服务器URL输入
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CupertinoTextField(
                    controller: _serverUrlController,
                    placeholder: 'Server URL (use 10.0.2.2 for localhost)',
                    keyboardType: TextInputType.url,
                    enabled: _knowledgeBases.isEmpty, // 禁用输入框
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C1C1E),
                      borderRadius: BorderRadius.circular(8),
                      border: _serverUrlError != null
                          ? Border.all(color: CupertinoColors.systemRed)
                          : null,
                    ),
                    style: const TextStyle(color: CupertinoColors.white),
                  ),
                  if (_serverUrlError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8, left: 4),
                      child: Text(
                        _serverUrlError!,
                        style: const TextStyle(
                          color: CupertinoColors.systemRed,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  // 只在未连接时显示 Connect 按钮
                  if (_knowledgeBases.isEmpty) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: CupertinoButton.filled(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        onPressed: _isLoading ? null : _fetchKnowledgeBases,
                        child: _isLoading
                            ? const CupertinoActivityIndicator()
                            : const Text('Connect'),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              // 知识库选择
              if (_knowledgeBases.isNotEmpty) ...[
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C1C1E),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: CupertinoButton(
                    padding: const EdgeInsets.all(16),
                    onPressed: () {
                      showCupertinoModalPopup(
                        context: context,
                        builder: (context) => Container(
                          color: CupertinoColors.systemBackground
                              .resolveFrom(context),
                          child: SafeArea(
                            top: false,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(
                                    top: 20.0,
                                    bottom: 0.0,
                                  ),
                                  child: Text(
                                    'Select Knowledge Base',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Container(
                                  constraints: BoxConstraints(
                                    maxHeight:
                                        MediaQuery.of(context).size.height *
                                            0.4,
                                  ),
                                  child: CupertinoListSection.insetGrouped(
                                    backgroundColor:
                                        CupertinoColors.systemGroupedBackground,
                                    children: _knowledgeBases.map((kb) {
                                      return CupertinoListTile(
                                        title: Text(kb.name),
                                        subtitle: Text(
                                          kb.location,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: CupertinoColors.systemGrey,
                                          ),
                                        ),
                                        trailing:
                                            _selectedKnowledgeBase?.location ==
                                                    kb.location
                                                ? const Icon(
                                                    CupertinoIcons.check_mark)
                                                : null,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12.0,
                                          horizontal: 16.0,
                                        ),
                                        onTap: () {
                                          setState(() {
                                            _selectedKnowledgeBase = kb;
                                          });
                                          Navigator.pop(context);
                                        },
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _selectedKnowledgeBase?.name ??
                              'Select Knowledge Base',
                          style: const TextStyle(color: CupertinoColors.white),
                        ),
                        const Icon(
                          CupertinoIcons.chevron_down,
                          color: CupertinoColors.white,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // 密码输入
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CupertinoTextField(
                      controller: _passwordController,
                      placeholder: 'Library Password',
                      obscureText: true,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1C1C1E),
                        borderRadius: BorderRadius.circular(8),
                        border: _passwordError != null
                            ? Border.all(color: CupertinoColors.systemRed)
                            : null,
                      ),
                      style: const TextStyle(color: CupertinoColors.white),
                    ),
                    if (_passwordError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8, left: 4),
                        child: Text(
                          _passwordError!,
                          style: const TextStyle(
                            color: CupertinoColors.systemRed,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 32),
                CupertinoButton.filled(
                  onPressed: _selectedKnowledgeBase != null &&
                          _passwordController.text.isNotEmpty &&
                          !_isLoading
                      ? _login
                      : null,
                  child: const Text('Login'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
