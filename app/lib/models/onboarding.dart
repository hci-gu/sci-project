import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

const int ONBOARDING_STEP_COUNT = 3;
final onboardingStepProvider = StateProvider<int>((ref) => 0);

final onboardingStepsprovider = Provider<List<FocusNode>>(
  (ref) => List<FocusNode>.generate(
    ONBOARDING_STEP_COUNT,
    (int i) => FocusNode(debugLabel: 'Onboarding Focus Node $i'),
    growable: false,
  ),
);

final onboardingDoneProvider = Provider<bool>(
    (ref) => ref.watch(onboardingStepProvider) == ONBOARDING_STEP_COUNT);
