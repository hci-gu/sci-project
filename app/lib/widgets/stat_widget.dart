import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:scimovement/theme/theme.dart';

enum Unit {
  calories,
  time,
  amount,
}

extension ParseToString on Unit {
  String displayString() {
    switch (this) {
      case Unit.calories:
        return 'kcal';
      case Unit.time:
        return 'min';
      case Unit.amount:
        return 'st';
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

  double get diff {
    return (current - previous).toDouble();
  }
}

enum StatWidgetMode {
  day,
  week,
}

class StatWidget extends StatelessWidget {
  final String title;
  final Unit unit;
  final WidgetValues values;
  final String asset;
  final StatWidgetMode mode;
  final Widget? action;

  const StatWidget({
    Key? key,
    this.title = 'Kalorier',
    this.mode = StatWidgetMode.day,
    this.action,
    required this.unit,
    required this.values,
    required this.asset,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double change = mode == StatWidgetMode.day
        ? values.percentChange
        : values.diff.toDouble();

    return _container(
      Column(
        children: [
          Row(
            children: [
              SvgPicture.asset(asset, height: 24),
              AppTheme.spacerHalf,
              Text(title, style: AppTheme.labelTiny),
            ],
          ),
          AppTheme.spacer,
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              AnimatedFlipCounter(
                value: values.current,
                duration: const Duration(milliseconds: 250),
                textStyle: AppTheme.headLine1.copyWith(
                  letterSpacing: 2,
                  height: 1,
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
          if (mode == StatWidgetMode.day)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  values.previous.toString(),
                  style: AppTheme.labelLarge.copyWith(height: 1),
                ),
                Text(
                  ' ${unit.displayString()}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                    height: 1,
                  ),
                )
              ],
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            textBaseline: TextBaseline.alphabetic,
            children: [
              iconForChange(change),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 30),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    mode == StatWidgetMode.day
                        ? '${values.percentChange.toStringAsFixed(1)}%'
                        : '${values.diff.toString()} ${unit.displayString()}',
                    style: AppTheme.labelTiny.copyWith(
                      color: colorForChange(change),
                    ),
                  ),
                ),
              ),
              Text(
                mode == StatWidgetMode.day
                    ? '  från igår.         '
                    : '  från förra veckan. ',
                style: AppTheme.labelTiny,
              ),
            ],
          ),
          action ?? Container(),
        ],
      ),
    );
  }

  Color colorForChange(double change) {
    bool isPositive = (unit == Unit.calories || unit == Unit.amount)
        ? change > 0
        : change < 0;
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
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8.0),
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
