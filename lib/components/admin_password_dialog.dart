import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Asks for the admin password (ADMIN_PASSWORD in .env).
// Returns true only when the correct password was entered.
Future<bool> askAdminPassword(BuildContext context) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (_) => const _AdminPasswordDialog(),
  );
  return ok == true;
}

// the dialog owns its text controller, so it is disposed only after the
// dialog has fully left the screen
class _AdminPasswordDialog extends StatefulWidget {
  const _AdminPasswordDialog();

  @override
  State<_AdminPasswordDialog> createState() => _AdminPasswordDialogState();
}

class _AdminPasswordDialogState extends State<_AdminPasswordDialog> {
  final TextEditingController _input = TextEditingController();
  bool _wrong = false;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _submit() {
    final expected = dotenv.maybeGet('ADMIN_PASSWORD') ?? '';
    if (expected.isNotEmpty && _input.text == expected) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _wrong = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      title: const Text('Enter Password', textAlign: TextAlign.center),
      content: SizedBox(
        width: 300,
        child: TextField(
          controller: _input,
          autofocus: true,
          obscureText: true,
          onSubmitted: (_) => _submit(),
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color.fromRGBO(230, 84, 0, 1)),
            ),
            errorText: _wrong ? 'Wrong password' : null,
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(onPressed: _submit, child: const Text('OK')),
      ],
    );
  }
}
