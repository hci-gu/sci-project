import 'package:animated_digit/animated_digit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:scimovement/theme/theme.dart';

enum Unit {
  calories,
  time,
}

extension ParseToString on Unit {
  String displayString() {
    switch (this) {
      case Unit.calories:
        return 'kcal';
      case Unit.time:
        return 'min';
      default:
        return toString();
    }
  }
}

class WidgetValues {
  final int previous;
  final int current;

  const WidgetValues(this.current, this.previous);

  double get percentChange {
    if (previous == 0) {
      return 0;
    }
    return ((current - previous) / previous) * 100;
  }
}

class StatWidget extends StatelessWidget {
  final Unit unit;
  final WidgetValues values;
  final String asset;

  const StatWidget({
    Key? key,
    required this.unit,
    required this.values,
    required this.asset,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return _container(
      Column(
        children: [
          SvgPicture.asset(asset, height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              AnimatedDigitWidget(
                value: values.current,
                duration: const Duration(milliseconds: 250),
                textStyle: AppTheme.headLine1.copyWith(
                  letterSpacing: 2,
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
                values.previous.toString(),
                style: AppTheme.labelLarge,
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
              iconForChange(values.percentChange),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 30),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '${values.percentChange.toStringAsFixed(1)}%',
                    style: AppTheme.labelTiny.copyWith(
                      color: colorForChange(values.percentChange),
                    ),
                  ),
                ),
              ),
              Text(
                ' from yesterday.',
                style: AppTheme.labelTiny,
              )
            ],
          )
        ],
      ),
    );
  }

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

  static Widget _container(Widget child) {
    return FittedBox(
      fit: BoxFit.contain,
      child: Container(
        decoration: AppTheme.widgetDecoration,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12.0),
          child: child,
        ),
      ),
    );
  }

  static Widget _emptyContainer(List<Widget> children) => _container(
        Center(
          child: SizedBox(
            width: 128,
            height: 128,
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: children),
          ),
        ),
      );

  static Widget error(String asset) => _emptyContainer([
        SvgPicture.asset(asset),
        AppTheme.spacer2x,
        const Text('error'),
      ]);

  static Widget loading(String asset) => _emptyContainer(
        [
          SvgPicture.asset(asset),
          AppTheme.spacer4x,
          const CircularProgressIndicator(),
        ],
      );
}
