import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scimovement/storage.dart';
import 'package:timeago/timeago.dart' as timeago;

final localeProvider = StateProvider<Locale?>((ref) {
  ref.listenSelf((previous, next) {
    if (next != null) {
      Storage().storeLanguageCode(next.languageCode);
      timeago.setDefaultLocale(next.languageCode);
    }
  });

  String? languageCode = Storage().getLanguageCode();
  if (languageCode != null) {
    return Locale(languageCode);
  }

  return null;
});
