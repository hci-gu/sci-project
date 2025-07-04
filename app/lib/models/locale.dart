import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scimovement/storage.dart';
import 'package:timeago/timeago.dart' as timeago;

class LocaleNotifier extends Notifier<Locale?> {
  @override
  Locale? build() {
    listenSelf((previous, next) {
      if (next != null) {
        Storage().storeLanguageCode(next.languageCode);
        timeago.setDefaultLocale(next.languageCode);
      }
    });

    final languageCode = Storage().getLanguageCode();
    if (languageCode != null) {
      timeago.setDefaultLocale(languageCode);
      return Locale(languageCode);
    }

    return null;
  }
}

final localeProvider =
    NotifierProvider<LocaleNotifier, Locale?>(LocaleNotifier.new);
