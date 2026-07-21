import 'dart:ui';
import 'package:flutter/material.dart';

/// Gerektigi yerlerde (ör. poster uzerindeki bilgi seritleri, modal'lar)
/// kullanilan hafif cam efekti (glassmorphism) kapsayicisi.
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final double blur;
  final Color tint;

  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius = 20,
    this.padding = const EdgeInsets.all(16),
    this.blur = 16,
    this.tint = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: tint.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: tint.withValues(alpha: 0.25), width: 1),
          ),
          child: child,
        ),
      ),
    );
  }
}
