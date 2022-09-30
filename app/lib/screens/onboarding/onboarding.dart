import 'package:flutter/material.dart';
import 'package:flutter_portal/flutter_portal.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scimovement/screens/onboarding/widgets/onboarding_home.dart';
import 'package:scimovement/screens/onboarding/widgets/onboarding_step.dart';

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Stack(
        children: const [
          Portal(
            child: OnboardingHomeScreen(),
          ),
          Positioned(
            bottom: 0,
            child: OnboardingStepWidget(),
          ),
        ],
      ),
    );
  }
}

class Discovery extends StatelessWidget {
  final Widget child;
  final Widget message;
  final bool visible;

  const Discovery({
    Key? key,
    required this.child,
    required this.message,
    required this.visible,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Barrier(
      visible: visible,
      child: PortalTarget(
        visible: visible,
        closeDuration: kThemeAnimationDuration,
        anchor: const Aligned(
          target: Alignment.center,
          follower: Alignment.center,
        ),
        portalFollower: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              IgnorePointer(
                child: child,
              ),
              message,
            ],
          ),
        ),
        child: child,
      ),
    );
  }
}

class Barrier extends StatelessWidget {
  const Barrier({
    Key? key,
    required this.visible,
    required this.child,
  }) : super(key: key);

  final Widget child;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    return PortalTarget(
      visible: visible,
      closeDuration: kThemeAnimationDuration,
      portalFollower: TweenAnimationBuilder<Color>(
        duration: kThemeAnimationDuration,
        tween: ColorTween(
          begin: Colors.transparent,
          end: visible ? Colors.black54 : Colors.transparent,
        ),
        builder: (context, color, child) {
          return ColoredBox(color: color);
        },
      ),
      child: child,
    );
  }
}

/// Non-nullable version of ColorTween.
class ColorTween extends Tween<Color> {
  ColorTween({required Color begin, required Color end})
      : super(begin: begin, end: end);

  @override
  Color lerp(double t) => Color.lerp(begin, end, t)!;
}
