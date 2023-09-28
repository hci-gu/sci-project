import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class ShakeWidget extends HookWidget {
  final Widget child;
  final int numberOfShakes;
  final double shakeAmount;

  const ShakeWidget({
    super.key,
    required this.child,
    this.numberOfShakes = 3,
    this.shakeAmount = 2.5,
  });

  @override
  Widget build(BuildContext context) {
    var animation = useAnimationController(
      duration: const Duration(milliseconds: 600),
    );

    useEffect(() {
      animation
        ..forward(from: 0)
        ..addListener(() async {
          if (animation.isCompleted) {
            await Future.delayed(const Duration(milliseconds: 1500));
            // check if we are disposed
            if (context.mounted) {
              animation.reset();
              animation.forward(
                from: 0,
              );
            }
          }
        });
      return () => animation.dispose();
    }, []);

    return AnimatedBuilder(
      animation: Tween(
        begin: 0.5,
        end: 1.0,
      ).animate(
        CurvedAnimation(
          parent: animation,
          curve: Curves.elasticOut,
        ),
      ),
      builder: (context, child) {
        double angle = sin(animation.value * pi * 2 * numberOfShakes) * 0.15;
        return Transform.rotate(
          angle: -angle,
          child: Transform.translate(
            offset: Offset(
              sin(animation.value * pi * 2 * numberOfShakes) * shakeAmount,
              0,
            ),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
