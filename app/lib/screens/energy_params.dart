import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:provider/provider.dart';
import 'package:scimovement/models/energy.dart';

import 'package:scimovement/models/settings.dart';
import 'package:scimovement/theme/theme.dart';

class EnergySettingsScreen extends HookWidget {
  const EnergySettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    EnergyModel energyModel = Provider.of<EnergyModel>(context);
    TextEditingController weightController =
        useTextEditingController(text: energyModel.params.weight.toString());
    TextEditingController injuryController = useTextEditingController(
        text: energyModel.params.injuryLevel.toString());
    TextEditingController wattController =
        useTextEditingController(text: energyModel.params.watt.toString());

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Settings',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            _activity(energyModel),
            const SizedBox(height: 8),
            Row(
              children: [
                _condition(energyModel),
                const SizedBox(width: 24),
                _gender(energyModel),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Weight',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              controller: weightController,
              onChanged: (String? value) {
                if (value != null) {
                  energyModel.updateParams('weight', int.tryParse(value) ?? 0);
                }
              },
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Injury Level',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              controller: injuryController,
              onChanged: (String? value) {
                if (value != null) {
                  energyModel.updateParams(
                      'injuryLevel', int.tryParse(value) ?? 0);
                }
              },
            ),
            const SizedBox(height: 16),
            if (energyModel.params.activity == Activity.skiErgo)
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Watt',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                controller: wattController,
                onChanged: (String? value) {
                  if (value != null) {
                    energyModel.updateParams('watt', int.tryParse(value) ?? 0);
                  }
                },
              ),
          ]),
    );
  }

  _activity(EnergyModel energyModel) {
    return Row(
      children: [
        const Text('Activity'),
        const SizedBox(width: 16),
        DropdownButton<Activity>(
          value: energyModel.params.activity,
          onChanged: (Activity? newValue) {
            energyModel.updateParams('activity', newValue);
          },
          items: Activity.values.map((Activity value) {
            return DropdownMenuItem<Activity>(
              value: value,
              child: Text(value.name),
            );
          }).toList(),
        )
      ],
    );
  }

  _condition(EnergyModel energyModel) {
    return Row(
      children: [
        const Text('Condition'),
        const SizedBox(width: 16),
        DropdownButton<Condition>(
          value: energyModel.params.condition,
          onChanged: (Condition? newValue) {
            energyModel.updateParams('condition', newValue);
          },
          items: Condition.values.map((Condition value) {
            return DropdownMenuItem<Condition>(
              value: value,
              child: Text(value.name),
            );
          }).toList(),
        )
      ],
    );
  }

  _gender(EnergyModel energyModel) {
    return Row(
      children: [
        const Text('Gender'),
        const SizedBox(width: 16),
        DropdownButton<Gender>(
          value: energyModel.params.gender,
          onChanged: (Gender? newValue) {
            energyModel.updateParams('gender', newValue);
          },
          items: Gender.values.map((Gender value) {
            return DropdownMenuItem<Gender>(
              value: value,
              child: Text(value.name),
            );
          }).toList(),
        )
      ],
    );
  }
}
