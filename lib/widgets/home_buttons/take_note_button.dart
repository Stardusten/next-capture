import 'package:flutter/cupertino.dart';
import '../../pages/note_editor_page.dart';

class TakeNoteButton extends StatelessWidget {
  const TakeNoteButton({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          CupertinoPageRoute(
            builder: (context) => const NoteEditorPage(),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        height: 100,
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
                'Take Note',
                style: TextStyle(
                  color: CupertinoColors.white,
                  fontSize: 16,
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomLeft,
              child: Icon(
                CupertinoIcons.pencil,
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
