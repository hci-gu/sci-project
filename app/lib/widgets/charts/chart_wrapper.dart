import 'package:flutter/material.dart';
import 'package:scimovement/gen_l10n/app_localizations.dart';

class ChartWrapper extends StatelessWidget {
  final Widget child;
  final bool isCard;
  final double aspectRatio;

  const ChartWrapper({
    super.key,
    required this.child,
    this.isCard = true,
    this.aspectRatio = 1.7,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: Container(
        decoration: isCard
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: const Color.fromRGBO(0, 0, 0, 0.1),
                  width: 1,
                ),
              )
            : null,
        child: Padding(
          padding: isCard
              ? const EdgeInsets.only(left: 8, right: 24, top: 24, bottom: 24)
              : const EdgeInsets.only(top: 24, bottom: 0, left: 0, right: 0),
          child: child,
        ),
      ),
    );
  }

  static ChartWrapper loading() => const ChartWrapper(
        isCard: false,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
  static ChartWrapper error(String err) => ChartWrapper(
        isCard: false,
        child: Center(
          child: Text(err),
        ),
      );
  static ChartWrapper empty(BuildContext context) => ChartWrapper(
        isCard: false,
        child: Center(
          child: Text(AppLocalizations.of(context)!.noData),
        ),
      );
}
