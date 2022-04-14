import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:scimovement/models/energy.dart';
import 'package:scimovement/theme/theme.dart';
import 'package:scimovement/widgets/accel_display.dart';
import 'package:scimovement/widgets/energy_display.dart';
import 'package:scimovement/screens/energy_params.dart';

class MeasureScreen extends HookWidget {
  const MeasureScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    ValueNotifier<bool> measuring = useState(false);
    EnergyModel energyModel = Provider.of<EnergyModel>(context);

    useEffect(() {
      Timer timer = Timer.periodic(const Duration(minutes: 1), (timer) {});
      if (measuring.value) {
        energyModel.setFrom(DateTime.now());
        energyModel.setTo(DateTime.now());
        energyModel.getEnergy();
        timer = Timer.periodic(const Duration(seconds: 15), (timer) {
          energyModel.setTo(DateTime.now());
          energyModel.getEnergy();
        });
      }
      return () => timer.cancel();
    }, [measuring.value]);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: ListView(
        shrinkWrap: true,
        children: [
          const SizedBox(height: 16),
          const EnergyDisplay(),
          AccelDisplay(showEmpty: measuring.value),
          Text('Select period', style: AppTheme.titleTextStyle),
          const SizedBox(height: 16),
          _fromTo(context, energyModel),
          const SizedBox(height: 16),
          const Center(child: Text('- Or -')),
          const SizedBox(height: 16),
          _startStop(context, measuring)
        ],
      ),
    );
  }

  Widget _startStop(BuildContext context, ValueNotifier<bool> measuring) {
    return TextButton.icon(
      style: AppTheme.buttonStyle,
      onPressed: () {
        measuring.value = !measuring.value;
      },
      icon: const Icon(Icons.timer, color: Colors.white),
      label: Text(
        measuring.value ? 'Stop' : 'Start timer',
        style: AppTheme.buttonTextStyle,
      ),
    );
  }

  Widget _fromTo(BuildContext context, EnergyModel energyModel) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Column(
          children: [
            const Text('From'),
            const SizedBox(height: 4),
            _clockButton(context, energyModel.from, (TimeOfDay time) {
              energyModel.setTimeOfDay('from', time);
            }),
          ],
        ),
        const SizedBox(width: 16),
        Column(
          children: [
            const Text('To'),
            const SizedBox(height: 4),
            _clockButton(context, energyModel.to, (TimeOfDay time) {
              energyModel.setTimeOfDay('to', time);
            })
          ],
        ),
      ],
    );
  }

  Widget _clockButton(BuildContext context, DateTime date, Function onPressed) {
    return TextButton.icon(
      style: AppTheme.buttonStyle,
      onPressed: () async {
        TimeOfDay? time = await _selectTime(
          context,
          TimeOfDay.fromDateTime(date),
        );
        if (time != null) {
          onPressed(time);
        }
      },
      icon: const Icon(Icons.timer, color: Colors.white),
      label: Text(
        DateFormat.Hm().format(date),
        style: AppTheme.buttonTextStyle,
      ),
    );
  }

  Future<TimeOfDay?> _selectTime(BuildContext context, TimeOfDay time) async {
    final TimeOfDay? newTime = await showTimePicker(
      context: context,
      initialTime: time,
    );
    return newTime;
  }
}
