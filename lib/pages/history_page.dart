import 'package:flutter/cupertino.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('History'),
        backgroundColor: CupertinoColors.black,
        border: null,
      ),
      backgroundColor: CupertinoColors.black,
      child: const SafeArea(
        child: Center(
          child: Text(
            'Sync History',
            style: TextStyle(color: CupertinoColors.white),
          ),
        ),
      ),
    );
  }
}
