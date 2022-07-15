import 'package:animated_digit/animated_digit.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scimovement/models/energy.dart';
import 'package:scimovement/theme/theme.dart';
import 'package:scimovement/widgets/energy_display.dart';
import 'package:scimovement/widgets/stat_widget.dart';

class CaloriesScreen extends StatelessWidget {
  const CaloriesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    EnergyModel energyModel = Provider.of<EnergyModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Calories',
          style: AppTheme.appBarTextStyle,
        ),
      ),
      body: Padding(
        padding: AppTheme.screenPadding,
        child: Column(
          children: [
            StatHeader(
              unit: Unit.calories,
              value: energyModel.energyTotal.toInt(),
            ),
            _separator(),
            const EnergyDisplay(isCard: false),
            _separator(),
          ],
        ),
      ),
    );
  }

  Widget _separator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Container(
        height: 1,
        color: const Color.fromRGBO(0, 0, 0, 0.1),
      ),
    );
  }
}

class StatHeader extends StatelessWidget {
  final Unit unit;
  final int value;

  const StatHeader({
    Key? key,
    required this.unit,
    required this.value,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Total',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            AnimatedDigitWidget(
              value: value,
              duration: const Duration(milliseconds: 250),
              textStyle: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                letterSpacing: 0,
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
        const Text(
          'Today',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}
