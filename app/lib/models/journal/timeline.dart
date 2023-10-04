import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final showTimelineProvider = StateProvider<bool>((ref) {
  ref.listenSelf((previous, next) {
    // force orientation
    if (next) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }
  });

  return false;
});
