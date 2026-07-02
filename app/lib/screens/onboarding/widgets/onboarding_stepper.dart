import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scimovement/models/onboarding.dart';
import 'package:scimovement/theme/theme.dart';
import 'package:scimovement/widgets/button.dart';
import 'package:scimovement/gen_l10n/app_localizations.dart';

class StepIndicator extends StatelessWidget {
  final int index;
  final int count;

  const StepIndicator({super.key, this.index = 0, this.count = 3});

  @override
  Widget build(BuildContext context) {
    final safeIndex = index.clamp(0, count - 1);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        count,
        (i) => Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.colors.primary),
              color:
                  safeIndex == i ? AppTheme.colors.primary : Colors.transparent,
            ),
          ),
        ),
      ),
    );
  }
}

class OnboardingStepper extends ConsumerWidget {
  const OnboardingStepper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shouldStack = MediaQuery.textScalerOf(context).scale(1) > 1.2;
    final step = ref.watch(onboardingStepProvider);

    return Container(
      width: MediaQuery.of(context).size.width,
      padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flex(
            direction: shouldStack ? Axis.vertical : Axis.horizontal,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment:
                shouldStack
                    ? CrossAxisAlignment.stretch
                    : CrossAxisAlignment.center,
            children: [
              step == 0
                  ? GestureDetector(
                    onTap: () {
                      ref.read(onboardingStepProvider.notifier).state =
                          onboardingStepCount;
                      if (ref.watch(onboardingStepProvider) ==
                          onboardingStepCount) {
                        context.goNamed('home');
                      }
                    },
                    child: Text(
                      AppLocalizations.of(context)!.skip,
                      style: AppTheme.labelLarge.copyWith(
                        decoration: TextDecoration.underline,
                      ),
                      textAlign:
                          shouldStack ? TextAlign.center : TextAlign.start,
                    ),
                  )
                  : Button(
                    width: 100,
                    title: AppLocalizations.of(context)!.back,
                    secondary: true,
                    onPressed:
                        () => ref.read(onboardingStepProvider.notifier).state--,
                  ),
              if (shouldStack) AppTheme.spacer2x,
              Button(
                width: 100,
                title:
                    step == onboardingStepCount - 1
                        ? AppLocalizations.of(context)!.finish
                        : AppLocalizations.of(context)!.next,
                onPressed: () {
                  ref.read(onboardingStepProvider.notifier).state++;
                  if (ref.watch(onboardingStepProvider) ==
                      onboardingStepCount) {
                    context.goNamed('home');
                  }
                },
              ),
            ],
          ),
          AppTheme.spacer,
          StepIndicator(index: step, count: onboardingStepCount),
        ],
      ),
    );
  }
}
