import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:scimovement/models/energy.dart';
import 'package:scimovement/theme/theme.dart';
import 'package:scimovement/widgets/energy_display.dart';
import 'package:scimovement/screens/energy_params.dart';

class MeasureScreen extends HookWidget {
  const MeasureScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    ValueNotifier<bool> measuring = useState(false);
    EnergyModel energyModel = Provider.of<EnergyModel>(context);

    useEffect(() {
      energyModel.getEnergy();
      return () => {};
    }, []);

    useEffect(() {
      Timer timer = Timer.periodic(const Duration(minutes: 1), (timer) {});
      if (measuring.value) {
        energyModel.setFrom(DateTime.now());
        energyModel.setTo(DateTime.now());
        energyModel.getEnergy();
        timer = Timer.periodic(const Duration(seconds: 10), (timer) {
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
          const SizedBox(height: 24),
          const EnergyDisplay(),
          const SizedBox(height: 24),
          _fromTo(context, energyModel),
          const SizedBox(height: 24),
          const Center(child: Text('- Or -')),
          const SizedBox(height: 24),
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
        measuring.value ? 'Stop' : 'Start from now',
        style: AppTheme.buttonTextStyle,
      ),
    );
  }

  Widget _fromTo(BuildContext context, EnergyModel energyModel) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        TextButton.icon(
          style: AppTheme.buttonStyle,
          onPressed: () async {
            TimeOfDay? time = await _selectTime(
              context,
              TimeOfDay.fromDateTime(energyModel.from),
            );
            if (time != null) {
              energyModel.setTimeOfDay('from', time);
            }
          },
          icon: const Icon(Icons.timer, color: Colors.white),
          label: Text(
            'From ${DateFormat.Hm().format(energyModel.from)}',
            style: AppTheme.buttonTextStyle,
          ),
        ),
        TextButton.icon(
          style: AppTheme.buttonStyle,
          onPressed: () async {
            TimeOfDay? time = await _selectTime(
              context,
              TimeOfDay.fromDateTime(energyModel.to),
            );
            if (time != null) {
              energyModel.setTimeOfDay('to', time);
            }
          },
          icon: const Icon(Icons.timer, color: Colors.white),
          label: Text(
            'To ${DateFormat.Hm().format(energyModel.to)}',
            style: AppTheme.buttonTextStyle,
          ),
        ),
      ],
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