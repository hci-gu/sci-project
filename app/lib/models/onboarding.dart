import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scimovement/storage.dart';

const int onboardingStepCount = 6;
final onboardingStepProvider = StateProvider<int>((ref) => 0);

final onboardingDoneProvider = Provider<bool>((ref) {
  bool isDone = Storage().getOnboardingDone() ||
      ref.watch(onboardingStepProvider) >= onboardingStepCount;
  if (isDone) {
    Storage().storeOnboardingDone(true);
  }
  return isDone;
});
