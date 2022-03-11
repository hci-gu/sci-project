import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:provider/provider.dart';
import 'package:scimovement/api.dart';
import 'package:scimovement/models/activity.dart';
import 'package:scimovement/widgets/energy_display.dart';
import 'package:scimovement/widgets/heart_rate_chart.dart';

class HomeScreen extends HookWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    ActivityModel activityModel = Provider.of<ActivityModel>(context);
    useEffect(() {
      activityModel.getHeartRates();
      return () => {};
    }, []);

    return Scaffold(
      appBar: AppBar(
        title: const Text('SCI-Movement'),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 16.0),
        child: ListView(
          children: [
            Center(
                child: Text('HeartRate',
                    style: Theme.of(context).textTheme.headline6)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => activityModel.goBack(),
                  icon: const Icon(Icons.arrow_back),
                ),
                Text(
                  activityModel.from.toString().substring(0, 10),
                ),
                IconButton(
                  onPressed: () => activityModel.goForward(),
                  icon: const Icon(Icons.arrow_forward),
                )
              ],
            ),
            HeartRateChart(
              heartRates: activityModel.heartRates,
              from: activityModel.from,
              to: activityModel.to,
            ),
            const SizedBox(
              height: 24,
            ),
            const EnergyDisplay(),
          ],
        ),
      ),
    );
  }
}
