import 'package:flutter/material.dart';
import 'package:scimovement/theme/theme.dart';

class ProgressIndicatorAround extends StatelessWidget {
  final double value;
  final double duration;
  final Widget child;

  final double size;
  final double strokeWidth;

  const ProgressIndicatorAround({
    super.key,
    this.size = 100,
    this.strokeWidth = 4,
    required this.child,
    required this.value,
    required this.duration,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          Positioned(
            child: SizedBox(
              height: size * 1.25 * MediaQuery.textScalerOf(context).scale(1),
              width: size * 1.25 * MediaQuery.textScalerOf(context).scale(1),
              child: CircularProgressIndicator(
                value: value / duration,
                strokeWidth: strokeWidth,
                backgroundColor: AppTheme.colors.black.withValues(alpha: 0.1),
              ),
            ),
          ),
          Center(child: child),
        ],
      ),
    );
  }
}
