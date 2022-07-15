import 'package:animated_digit/animated_digit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:scimovement/theme/theme.dart';

enum Unit {
  calories,
  sedentary,
}

extension ParseToString on Unit {
  String displayString() {
    switch (this) {
      case Unit.calories:
        return 'kcal';
      case Unit.sedentary:
        return 'min';
      default:
        return toString();
    }
  }
}

class StatWidget extends StatelessWidget {
  final Unit unit;
  final int value;
  final int oldValue;
  final String asset;

  const StatWidget({
    Key? key,
    required this.unit,
    required this.value,
    required this.oldValue,
    required this.asset,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          width: 1.0,
          color: const Color.fromRGBO(0, 0, 0, 0.1),
        ),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12.0),
        child: Column(
          children: [
            SvgPicture.asset(asset),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                AnimatedDigitWidget(
                  value: value,
                  duration: const Duration(milliseconds: 250),
                  textStyle: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  ' ${unit.displayString()}',
                  style: const TextStyle(
                    color: Colors.grey,
                  ),
                )
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  oldValue.toString(),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  ' ${unit.displayString()}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                )
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              textBaseline: TextBaseline.alphabetic,
              children: [
                iconForChange(calcPercent),
                Text(
                  '${calcPercent.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: colorForChange(calcPercent),
                  ),
                ),
                const Text(
                  ' from yesterday.',
                  style: TextStyle(
                    fontSize: 11,
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }

  double get calcPercent => ((value - oldValue) / oldValue) * 100;

  Color colorForChange(double change) {
    bool isPositive = unit == Unit.calories ? change > 0 : change < 0;
    if (change == 0) {
      return Colors.grey;
    }
    return isPositive ? AppTheme.colors.success : AppTheme.colors.error;
  }

  Widget iconForChange(double change) {
    bool isPositive = change > 0;

    if (isPositive) {
      return Icon(
        Icons.arrow_drop_up,
        color: colorForChange(change),
      );
    }
    return Icon(
      Icons.arrow_drop_down,
      color: colorForChange(change),
    );
  }
}
