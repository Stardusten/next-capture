import 'package:flutter/cupertino.dart';
import 'package:flutter_demo/widgets/toast.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class NoteEditorPage extends StatefulWidget {
  const NoteEditorPage({super.key});

  @override
  State<NoteEditorPage> createState() => _NoteEditorPageState();
}

class _NoteEditorPageState extends State<NoteEditorPage> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    setState(() {
      _hasChanges = _controller.text.isNotEmpty;
    });
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;

    final result = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Discard Changes?'),
        content: const Text(
          'You have unsaved changes. Are you sure you want to leave? Your changes will be lost.',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context, false),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Discard'),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  Future<void> _saveNote() async {
    // TODO: 实现保存功能
    setState(() {
      _hasChanges = false;
    });
    if (mounted) {
      Toast.show(
        context,
        'Note saved successfully',
        ToastType.success,
      );
    }
  }

  void _convertToTodo() {
    final text = _controller.text;
    final selection = _controller.selection;
    if (!selection.isValid) return;

    // 获取当前行的内容
    final lines = text.split('\n');
    var currentLine = '';
    var currentLineStart = 0;
    var currentLineEnd = 0;

    for (var i = 0; i < lines.length; i++) {
      currentLineEnd = currentLineStart + lines[i].length;
      if (currentLineStart <= selection.baseOffset &&
          selection.baseOffset <= currentLineEnd) {
        currentLine = lines[i];
        break;
      }
      currentLineStart = currentLineEnd + 1;
    }

    // 如果已经是待办项，则不处理
    if (currentLine.trimLeft().startsWith('- [ ]') ||
        currentLine.trimLeft().startsWith('- [x]')) {
      return;
    }

    // 如果是普通列表项，转换为待办
    if (currentLine.trimLeft().startsWith('-')) {
      final indent = currentLine.indexOf('-');
      final newLine =
          '${' ' * indent}- [ ] ${currentLine.substring(indent + 2)}';
      final newText =
          text.replaceRange(currentLineStart, currentLineEnd, newLine);

      _controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(
          offset: currentLineStart + newLine.length,
        ),
      );
    }
  }

  void _indent() {
    final text = _controller.text;
    final selection = _controller.selection;
    if (!selection.isValid) return;

    // 获取当前行
    final lines = text.split('\n');
    var currentLine = '';
    var currentLineStart = 0;
    var currentLineEnd = 0;

    for (var i = 0; i < lines.length; i++) {
      currentLineEnd = currentLineStart + lines[i].length;
      if (currentLineStart <= selection.baseOffset &&
          selection.baseOffset <= currentLineEnd) {
        currentLine = lines[i];
        break;
      }
      currentLineStart = currentLineEnd + 1;
    }

    // 只处理列表项
    if (currentLine.trimLeft().startsWith('-')) {
      final newLine = '  $currentLine';
      final newText =
          text.replaceRange(currentLineStart, currentLineEnd, newLine);

      _controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(
          offset: selection.baseOffset + 2,
        ),
      );
    }
  }

  void _unindent() {
    final text = _controller.text;
    final selection = _controller.selection;
    if (!selection.isValid) return;

    // 获取当前行
    final lines = text.split('\n');
    var currentLine = '';
    var currentLineStart = 0;
    var currentLineEnd = 0;

    for (var i = 0; i < lines.length; i++) {
      currentLineEnd = currentLineStart + lines[i].length;
      if (currentLineStart <= selection.baseOffset &&
          selection.baseOffset <= currentLineEnd) {
        currentLine = lines[i];
        break;
      }
      currentLineStart = currentLineEnd + 1;
    }

    // 只处理有缩进的列表项
    if (currentLine.startsWith('  ') &&
        currentLine.trimLeft().startsWith('-')) {
      final newLine = currentLine.substring(2);
      final newText =
          text.replaceRange(currentLineStart, currentLineEnd, newLine);

      _controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(
          offset: selection.baseOffset - 2,
        ),
      );
    }
  }

  void _addNewLine() {
    final text = _controller.text;
    final selection = _controller.selection;
    if (!selection.isValid) return;

    // 获取当前行
    final lines = text.split('\n');
    var currentLineStart = 0;
    var currentLineEnd = 0;
    var currentLineIndex = 0;

    // 找到当前行
    for (var i = 0; i < lines.length; i++) {
      currentLineEnd = currentLineStart + lines[i].length;
      if (currentLineStart <= selection.baseOffset &&
          selection.baseOffset <= currentLineEnd) {
        currentLineIndex = i;
        break;
      }
      currentLineStart = currentLineEnd + 1;
    }

    final currentLine = lines[currentLineIndex];

    // 如果当前行是列表项，在其后插入新的列表项
    if (currentLine.trimLeft().startsWith('-')) {
      final indent = ' ' * currentLine.indexOf('-');
      final listItem = '\n$indent- ';

      // 在当前行末尾插入新行
      final newText = text.replaceRange(
        currentLineEnd,
        currentLineEnd,
        listItem,
      );

      _controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(
          offset: currentLineEnd + listItem.length,
        ),
      );
    } else {
      // 如果不是列表项，使用之前的逻辑
      String indent = '';
      if (currentLineIndex > 0 &&
          lines[currentLineIndex - 1].trimLeft().startsWith('-')) {
        final previousLine = lines[currentLineIndex - 1];
        indent = ' ' * (previousLine.indexOf('-'));
      }

      final listItem = '$indent- ';
      final newText = text.replaceRange(
        selection.baseOffset,
        selection.extentOffset,
        listItem,
      );

      _controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(
          offset: selection.baseOffset + listItem.length,
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: const Text('Take Note'),
          backgroundColor: CupertinoColors.black,
          border: null,
          trailing: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: _hasChanges ? _saveNote : null,
            child: Text(
              'Save',
              style: TextStyle(
                color: _hasChanges
                    ? CupertinoColors.systemBlue
                    : CupertinoColors.systemGrey,
              ),
            ),
          ),
        ),
        backgroundColor: CupertinoColors.black,
        child: SafeArea(
          child: Column(
            children: [
              // 编辑器区域
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: CupertinoTextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    style: const TextStyle(
                      color: CupertinoColors.white,
                      fontSize: 18,
                    ),
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    decoration: null,
                    cursorColor: CupertinoColors.systemBlue,
                    placeholder: 'Start typing...',
                    placeholderStyle: TextStyle(
                      color: CupertinoColors.systemGrey.withOpacity(0.6),
                      fontSize: 16,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              // 工具栏
              Container(
                height: 50,
                decoration: const BoxDecoration(
                  color: Color(0xFF1C1C1E),
                  border: Border(
                    top: BorderSide(
                      color: Color(0xFF2C2C2E),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // 转为待办按钮
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: _convertToTodo,
                      child: const Icon(
                        CupertinoIcons.checkmark_square,
                        color: CupertinoColors.white,
                        size: 24,
                      ),
                    ),
                    // 缩进按钮
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: _indent,
                      child: const Icon(
                        LucideIcons.indentIncrease,
                        color: CupertinoColors.white,
                        size: 24,
                      ),
                    ),
                    // 反缩进按钮
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: _unindent,
                      child: const Icon(
                        LucideIcons.indentDecrease,
                        color: CupertinoColors.white,
                        size: 24,
                      ),
                    ),
                    // 插入 - 按钮
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: _addNewLine,
                      child: const Icon(
                        LucideIcons.minus,
                        color: CupertinoColors.white,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
