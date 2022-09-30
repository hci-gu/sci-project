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
        ONBOARDING_STEP_COUNT,
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

class OnboardingStepWidget extends ConsumerWidget {
  const OnboardingStepWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: MediaQuery.of(context).size.width,
      padding: const EdgeInsets.symmetric(
        horizontal: 32.0,
        vertical: 24.0,
      ),
      decoration: BoxDecoration(
        color: AppTheme.colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () {
                  ref.read(onboardingStepProvider.notifier).state =
                      ONBOARDING_STEP_COUNT;
                },
                child: Text(
                  'Hoppa över',
                  style: AppTheme.labelLarge.copyWith(
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              Button(
                width: 100,
                title: ref.watch(onboardingStepProvider) ==
                        ONBOARDING_STEP_COUNT - 1
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

class OnboardingStepMessage extends StatelessWidget {
  final String title;
  final String text;

  const OnboardingStepMessage({
    Key? key,
    required this.title,
    required this.text,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: AppTheme.colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 16.0,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTheme.labelXLarge,
          ),
          Text(
            text,
            style: AppTheme.paragraphMedium,
          )
        ],
      ),
    );
  }
}
