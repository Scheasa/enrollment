import 'package:flutter/material.dart';

/// Asks for a short text. Returns the text (empty if optional and left blank),
/// or null if the user cancelled.
Future<String?> showNoteDialog(
  BuildContext context, {
  required String title,
  required String label,
  required String confirmLabel,
  bool required = false,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _NoteDialog(
      title: title,
      label: label,
      confirmLabel: confirmLabel,
      required: required,
    ),
  );
}

class _NoteDialog extends StatefulWidget {
  final String title;
  final String label;
  final String confirmLabel;
  final bool required;

  const _NoteDialog({
    required this.title,
    required this.label,
    required this.confirmLabel,
    required this.required,
  });

  @override
  State<_NoteDialog> createState() => _NoteDialogState();
}

class _NoteDialogState extends State<_NoteDialog> {
  final _ctrl = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _confirm() {
    final text = _ctrl.text.trim();
    if (widget.required && text.isEmpty) {
      setState(() => _error = 'Please enter a reason');
      return;
    }
    Navigator.of(context).pop(text);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _ctrl,
        autofocus: true,
        maxLines: 3,
        maxLength: 500,
        decoration: InputDecoration(
          labelText: widget.label,
          errorText: _error,
          border: const OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _confirm, child: Text(widget.confirmLabel)),
      ],
    );
  }
}
