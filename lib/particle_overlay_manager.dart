import 'package:flutter/material.dart';

import 'screens/add_edit_bird_screen.dart' show ParticleBurst;

class ParticleOverlayManager {
  static void showParticleBurst(BuildContext context, Offset globalPosition, Color color) {
    final overlay = Overlay.of(context);
    if (overlay == null) return;
    final renderBox = context.findRenderObject() as RenderBox?;
    final overlayBox = overlay.context.findRenderObject() as RenderBox?;
    if (overlayBox == null) return;
    final Offset overlayPosition = overlayBox.globalToLocal(globalPosition);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => Positioned(
        left: overlayPosition.dx - 30,
        top: overlayPosition.dy - 30,
        child: ParticleBurst(
          color: color,
          size: 60,
          onCompleted: () {
            entry.remove();
          },
        ),
      ),
    );
    overlay.insert(entry);
  }
} 