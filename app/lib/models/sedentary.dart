import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scimovement/api.dart';
import 'package:scimovement/models/config.dart';

final sedentaryProvider =
    FutureProvider.family<int, Pagination>((ref, pagination) async {
  DateTime date = ref.watch(dateProvider);

  return Api().getActivity(pagination.from(date), pagination.to(date));
});
