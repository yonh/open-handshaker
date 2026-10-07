import 'dart:typed_data';

import 'package:flutter/material.dart';

/// Thumbnail from raw bytes with graceful fallback when bytes are missing
/// or undecodable.
class ThumbImage extends StatelessWidget {
  const ThumbImage({
    super.key,
    required this.bytes,
    this.fit = BoxFit.cover,
    this.icon = Icons.image_outlined,
  });

  final List<int>? bytes;
  final BoxFit fit;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final b = bytes;
    if (b == null || b.isEmpty) {
      return Center(
        child: Icon(icon,
            size: 36, color: Theme.of(context).colorScheme.outline),
      );
    }
    return Image.memory(
      Uint8List.fromList(b),
      fit: fit,
      gaplessPlayback: true,
      errorBuilder: (_, _, _) => Center(
        child: Icon(icon,
            size: 36, color: Theme.of(context).colorScheme.outline),
      ),
    );
  }
}

/// Selectable media grid card: thumbnail + label + corner check overlay.
class MediaTile extends StatelessWidget {
  const MediaTile({
    super.key,
    required this.label,
    this.subtitle,
    this.thumbnail,
    this.icon = Icons.image_outlined,
    this.badge,
    required this.selected,
    this.onTap,
    this.onDoubleTap,
    this.onLongPress,
  });

  final String label;
  final String? subtitle;
  final List<int>? thumbnail;
  final IconData icon;
  final Widget? badge;
  final bool selected;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      onDoubleTap: onDoubleTap,
      onLongPress: onLongPress,
      child: Card(
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        color: selected ? scheme.primaryContainer : scheme.surfaceContainerLow,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ColoredBox(
                    color: scheme.surfaceContainerHighest,
                    child: ThumbImage(bytes: thumbnail, icon: icon),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(6, 4, 6, 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11)),
                      if (subtitle != null)
                        Text(subtitle!,
                            style: TextStyle(
                                fontSize: 10, color: scheme.outline)),
                    ],
                  ),
                ),
              ],
            ),
            if (badge != null)
              Positioned(right: 4, bottom: 34, child: badge!),
            if (selected)
              Positioned(
                right: 4,
                top: 4,
                child: Icon(Icons.check_circle,
                    size: 20, color: scheme.primary),
              ),
          ],
        ),
      ),
    );
  }
}
