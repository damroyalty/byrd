import 'package:flutter/material.dart';
import 'particle_overlay_manager.dart';

class TapParticle extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color color;
  const TapParticle({super.key, required this.child, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapDown: (details) {
        ParticleOverlayManager.showParticleBurst(
          context,
          details.globalPosition,
          color,
        );
      },
      onTap: onTap,
      child: child,
    );
  }
} 