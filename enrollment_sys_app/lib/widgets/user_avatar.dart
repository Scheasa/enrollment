import 'dart:typed_data';

import 'package:flutter/material.dart';

/// Round profile picture. Shows (in order): a just-picked photo, the saved
/// photo from the server, or the user's first letter.
class UserAvatar extends StatelessWidget {
  final String name;
  final String? url;
  final Uint8List? bytes;
  final double radius;

  const UserAvatar({
    super.key,
    required this.name,
    this.url,
    this.bytes,
    this.radius = 40,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final trimmed = name.trim();

    final initials = Container(
      color: scheme.primaryContainer,
      alignment: Alignment.center,
      child: Text(
        trimmed.isEmpty ? '?' : trimmed[0].toUpperCase(),
        style: TextStyle(
          fontSize: radius * 0.8,
          fontWeight: FontWeight.bold,
          color: scheme.onPrimaryContainer,
        ),
      ),
    );

    Widget child = initials;
    if (bytes != null) {
      child = Image.memory(bytes!, fit: BoxFit.cover);
    } else if (url != null) {
      child = Image.network(
        url!,
        fit: BoxFit.cover,
        // On Flutter web, falls back to a plain <img> when CORS blocks the image.
        webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
        errorBuilder: (context, error, stack) => initials,
      );
    }

    return ClipOval(
      child: SizedBox(width: radius * 2, height: radius * 2, child: child),
    );
  }
}
