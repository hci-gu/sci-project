import 'package:flutter/material.dart';
import 'package:scimovement/gen_l10n/app_localizations.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scimovement/models/locale.dart';
import 'package:scimovement/widgets/button.dart';

class LocaleSelect extends HookConsumerWidget {
  final GlobalKey _key = LabeledGlobalKey("button_icon");
  late Offset buttonPosition;
  late Size buttonSize;
  late AnimationController _animationController;
  late OverlayEntry _overlayEntry;
  final List<Locale> languages = AppLocalizations.supportedLocales;
  final bool small;

  LocaleSelect({super.key, this.small = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var isOpen = useState(false);
    _animationController = useAnimationController(
      duration: const Duration(milliseconds: 300),
    );
    Locale currentLocale =
        ref.watch(localeProvider) ?? Localizations.localeOf(context);

    return Button(
      key: _key,
      onPressed: () {
        if (isOpen.value) {
          close(isOpen);
        } else {
          open(context, ref, isOpen);
        }
      },
      title: displayLanguage(currentLocale),
      rounded: true,
      width: small ? 70 : 150,
      size: ButtonSize.small,
      icon: Icons.keyboard_arrow_down,
      flipIcon: true,
      // secondary: true,
    );
  }

  void open(BuildContext context, WidgetRef ref, isOpen) {
    findButton();
    _animationController.forward();
    _overlayEntry = _overlayEntryBuilder(context, ref, isOpen);
    Overlay.of(context).insert(_overlayEntry);
    isOpen.value = true;
  }

  void close(ValueNotifier<bool> isOpen) {
    _overlayEntry.remove();
    _animationController.reverse();
    isOpen.value = false;
  }

  void findButton() {
    RenderBox renderBox = _key.currentContext!.findRenderObject() as RenderBox;
    buttonSize = renderBox.size;
    buttonPosition = renderBox.localToGlobal(Offset.zero);
  }

  String displayLanguage(Locale locale) {
    switch (locale.languageCode) {
      case 'en':
        return small ? '🇬🇧' : '🇬🇧   English';
      case 'sv':
        return small ? '🇸🇪' : '🇸🇪   Swedish';
    }
    return '';
  }

  OverlayEntry _overlayEntryBuilder(
      BuildContext context, WidgetRef ref, isOpen) {
    return OverlayEntry(
      builder: (_) {
        return Positioned(
          top: buttonPosition.dy + buttonSize.height,
          left: buttonPosition.dx,
          width: buttonSize.width,
          child: Material(
            color: Colors.transparent,
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 15.0),
                  child: Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withValues(alpha: 0.1),
                          spreadRadius: 3,
                          blurRadius: 3,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: List.generate(languages.length, (index) {
                        return GestureDetector(
                          onTap: () {
                            ref.read(localeProvider.notifier).state =
                                languages[index];
                            close(isOpen);
                          },
                          child: Container(
                            width: buttonSize.width,
                            height: buttonSize.height,
                            alignment: Alignment.center,
                            child: Text(
                              displayLanguage(languages[index]),
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
