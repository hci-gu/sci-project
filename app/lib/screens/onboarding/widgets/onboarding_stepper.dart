import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scimovement/models/onboarding.dart';
import 'package:scimovement/theme/theme.dart';
import 'package:scimovement/widgets/button.dart';

class StepIndicator extends StatelessWidget {
  final int index;

  const StepIndicator({
    Key? key,
    this.index = 0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        onboardingStepCount,
        (i) => Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.colors.primary,
              ),
              color: index == i ? AppTheme.colors.primary : Colors.transparent,
            ),
          ),
        ),
      ),
    );
  }
}

class OnboardingStepper extends ConsumerWidget {
  const OnboardingStepper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: MediaQuery.of(context).size.width,
      padding: const EdgeInsets.symmetric(
        horizontal: 32.0,
        vertical: 24.0,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ref.watch(onboardingStepProvider) == 0
                  ? GestureDetector(
                      onTap: () {
                        ref.read(onboardingStepProvider.notifier).state =
                            onboardingStepCount;
                      },
                      child: Text(
                        'Hoppa över',
                        style: AppTheme.labelLarge.copyWith(
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    )
                  : Button(
                      width: 100,
                      title: 'Tillbaka',
                      secondary: true,
                      onPressed: () =>
                          ref.read(onboardingStepProvider.notifier).state--,
                    ),
              Button(
                width: 100,
                title:
                    ref.watch(onboardingStepProvider) == onboardingStepCount - 1
                        ? 'Avsluta'
                        : 'Nästa',
                onPressed: () =>
                    ref.read(onboardingStepProvider.notifier).state++,
              )
            ],
          ),
          AppTheme.spacer,
          StepIndicator(
            index: ref.watch(onboardingStepProvider),
          )
        ],
      ),
    );
  }
}
