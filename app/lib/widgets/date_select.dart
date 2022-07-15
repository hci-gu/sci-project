import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scimovement/models/activity.dart';
import 'package:scimovement/models/energy.dart';
import 'package:scimovement/widgets/button.dart';

class DateSelect extends StatelessWidget {
  const DateSelect({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    ActivityModel activityModel = Provider.of<ActivityModel>(context);
    EnergyModel energyModel = Provider.of<EnergyModel>(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: () {
            activityModel.goBack();
            energyModel.setDate(activityModel.from);
            energyModel.getEnergy();
          },
          icon: const Icon(Icons.arrow_back_ios_new),
        ),
        Button(
          width: 120,
          title: _textForButton(activityModel),
          subtitle: !activityModel.canFoForward
              ? activityModel.from.toString().substring(0, 10)
              : null,
          onPressed: () {},
        ),
        if (activityModel.canFoForward)
          IconButton(
            onPressed: () {
              activityModel.goForward();
              energyModel.setDate(activityModel.from);
              energyModel.getEnergy();
            },
            icon: const Icon(Icons.arrow_forward),
          )
        else
          const SizedBox(width: 40)
      ],
    );
  }

  String _textForButton(ActivityModel activityModel) {
    if (!activityModel.canFoForward) {
      return 'Today';
    }
    return activityModel.from.toString().substring(0, 10);
  }
}
