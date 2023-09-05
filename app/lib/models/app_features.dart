import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scimovement/storage.dart';

enum AppFeature {
  watch,
  pressureRelease,
  pain,
  exercise,
}

final appFeaturesProvider = StateProvider<List<AppFeature>>((ref) {
  ref.listenSelf((previous, next) {
    Storage().storeAppFeatures(next);
  });

  return Storage().getAppFeatures();
});
