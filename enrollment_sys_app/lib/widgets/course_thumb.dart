import 'package:flutter/material.dart';

import '../core/app_colors.dart';

/// Soft translucent circle used to decorate colored cards.
class DecorBubble extends StatelessWidget {
  final double size;
  final double opacity;

  const DecorBubble({super.key, required this.size, this.opacity = 0.14});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: opacity),
      ),
    );
  }
}

/// Course picture, or a colored panel with a category icon when there is none.
class CourseThumb extends StatelessWidget {
  final String category;
  final String? url;
  final double width;
  final double height;
  final Color accent;

  const CourseThumb({
    super.key,
    required this.category,
    required this.width,
    required this.height,
    this.url,
    this.accent = AppColors.sky,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(22);

    final fallback = Container(
      width: width,
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: accent, borderRadius: radius),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            right: -height * 0.2,
            top: -height * 0.2,
            child: DecorBubble(size: height * 0.9, opacity: 0.14),
          ),
          Positioned(
            left: -height * 0.15,
            bottom: -height * 0.25,
            child: DecorBubble(size: height * 0.7, opacity: 0.10),
          ),
          Icon(
            category == 'english' ? Icons.translate : Icons.computer,
            size: height * 0.42,
            color: Colors.white,
          ),
        ],
      ),
    );

    if (url == null) return fallback;

    return ClipRRect(
      borderRadius: radius,
      child: Image.network(
        url!,
        width: width,
        height: height,
        fit: BoxFit.cover,
        // On Flutter web, falls back to a plain <img> when CORS blocks the image.
        webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
        errorBuilder: (context, error, stack) => fallback,
      ),
    );
  }
}
