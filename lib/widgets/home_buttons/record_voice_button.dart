import 'package:flutter/cupertino.dart';
import '../../pages/voice_memo_page.dart';

class RecordVoiceButton extends StatelessWidget {
  const RecordVoiceButton({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          CupertinoPageRoute(
            builder: (context) => const VoiceMemoPage(),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(16),
        child: const Stack(
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: Text(
                'Record Voice',
                style: TextStyle(
                  color: CupertinoColors.white,
                  fontSize: 16,
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomLeft,
              child: Icon(
                CupertinoIcons.mic,
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
