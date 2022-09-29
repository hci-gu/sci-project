import 'package:flutter/material.dart';
import 'package:flutter_portal/flutter_portal.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scimovement/models/onboarding.dart';
import 'package:scimovement/screens/onboarding/widgets/onboarding_home.dart';
import 'package:scimovement/screens/onboarding/widgets/onboarding_step.dart';

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Stack(
        children: [
          const Portal(
            child: OnboardingHomeScreen(),
          ),
          const Positioned(
            bottom: 0,
            child: OnboardingStepWidget(),
          ),
          if (ref.watch(onboardingStepProvider) == 0)
            const Positioned(
              top: 416,
              left: 16,
              child: OnboardingStepMessage(
                title: 'Rörelse',
                text:
                    'Här kan du se hur många kalorier du har förbränt idag. Det ger dig också en jämförelse med din genomsnittliga dag förra veckan.',
              ),
            ),
          if (ref.watch(onboardingStepProvider) == 1)
            const Positioned(
              top: 250,
              left: 16,
              child: OnboardingStepMessage(
                title: 'Kalorier',
                text:
                    'Här kan du se hur många kalorier du har förbränt idag. Det ger dig också en jämförelse med din genomsnittliga dag förra veckan.',
              ),
            ),
          if (ref.watch(onboardingStepProvider) == 2)
            const Positioned(
              top: 250,
              right: 16,
              child: OnboardingStepMessage(
                title: 'Stillasittande',
                text:
                    'Här kan du se hur många kalorier du har förbränt idag. Det ger dig också en jämförelse med din genomsnittliga dag förra veckan.',
              ),
            ),
        ],
      ),
    );
  }
}

class Discovery extends StatelessWidget {
  const Discovery({
    Key? key,
    required this.visible,
    required this.onClose,
    required this.description,
    required this.child,
  }) : super(key: key);

  final Widget child;
  final Widget description;
  final bool visible;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Barrier(
      visible: visible,
      onClose: onClose,
      child: PortalTarget(
        visible: visible,
        closeDuration: kThemeAnimationDuration,
        anchor: const Aligned(
          target: Alignment.center,
          follower: Alignment.center,
        ),
        portalFollower: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: IgnorePointer(
                child: child,
              ),
            )
          ],
        ),
        child: child,
      ),
    );
  }
}

class Barrier extends StatelessWidget {
  const Barrier({
    Key? key,
    required this.onClose,
    required this.visible,
    required this.child,
  }) : super(key: key);

  final Widget child;
  final VoidCallback onClose;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    return PortalTarget(
      visible: visible,
      closeDuration: kThemeAnimationDuration,
      portalFollower: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onClose,
        child: TweenAnimationBuilder<Color>(
          duration: kThemeAnimationDuration,
          tween: ColorTween(
            begin: Colors.transparent,
            end: visible ? Colors.black54 : Colors.transparent,
          ),
          builder: (context, color, child) {
            return ColoredBox(color: color);
          },
        ),
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
