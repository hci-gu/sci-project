import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scimovement/api.dart';
import 'package:scimovement/storage.dart';

class UserState extends StateNotifier<User?> {
  UserState() : super(null);
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    String? userId = await Storage.getUserId();
    _initialized = true;

    if (userId != null) {
      await login(userId);
    }
  }

  Future<void> login(String userId) async {
    state = await Api().getUser(userId);
    if (state != null) {
      await Storage.storeUserId(userId);
    }
  }

  Future<void> logout() async {
    state = null;
  }

  Future<void> update(Map<String, dynamic> update) async {
    state = await Api().updateUser(update);
  }
}

final userProvider = StateNotifierProvider<UserState, User?>((ref) {
  UserState state = UserState();
  state.init();
  return state;
});
