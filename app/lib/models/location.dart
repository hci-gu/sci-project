import 'package:background_fetch/background_fetch.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scimovement/api.dart';

Future<Position?> _determinePosition() async {
  bool serviceEnabled;
  LocationPermission permission;

  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    return Future.error('Location services are disabled.');
  }

  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      return Future.error('Location permissions are denied');
    }
  }

  if (permission == LocationPermission.deniedForever) {
    return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.');
  }

  return Geolocator.getCurrentPosition();
}

typedef PositionFunction<T> = Future<Position?> Function();

Future<int> initBackgroundFetch() => BackgroundFetch.configure(
        BackgroundFetchConfig(
          minimumFetchInterval: 15,
          stopOnTerminate: false,
          enableHeadless: true,
          requiresBatteryNotLow: false,
          requiresCharging: false,
          requiresStorageNotLow: false,
          requiresDeviceIdle: false,
          requiredNetworkType: NetworkType.ANY,
        ), (String taskId) async {
      // do stuff here
      Position? position = await _determinePosition();
      if (position != null) {
        await Api().sendPosition(position);
      }
      BackgroundFetch.finish(taskId);
    }, (String taskId) async {
      BackgroundFetch.finish(taskId);
    });

final locationActivatedProvider = StateProvider<bool>((ref) => false);

final backgroundFetchProvider = FutureProvider<int>((ref) async {
  bool activated = ref.watch(locationActivatedProvider);

  if (activated) {
    _determinePosition();
    return initBackgroundFetch();
  } else {
    return -1;
  }
});

final backgroundStarter = Provider.autoDispose<void>((ref) async {
  int status = await ref.watch(backgroundFetchProvider.future);

  if (status == BackgroundFetch.STATUS_AVAILABLE) {
    BackgroundFetch.start();
  }
});
