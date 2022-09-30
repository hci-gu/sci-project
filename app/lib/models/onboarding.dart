import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scimovement/storage.dart';

const int ONBOARDING_STEP_COUNT = 5;
final onboardingStepProvider = StateProvider<int>((ref) => 0);

final onboardingDoneProvider = Provider<bool>((ref) {
  bool isDone = ref.watch(onboardingStepProvider) == ONBOARDING_STEP_COUNT;
  if (isDone) {
    Storage.storeOnboardingDone(true);
  }
  return isDone;
});
