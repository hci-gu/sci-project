import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:scimovement/models/activity.dart';
import 'package:scimovement/models/energy.dart';
import 'package:scimovement/models/push.dart';
import 'package:scimovement/models/settings.dart';
import 'package:scimovement/screens/settings.dart';
import 'package:scimovement/theme/theme.dart';
import 'package:scimovement/widgets/energy_display.dart';
import 'package:scimovement/widgets/heart_rate_chart.dart';

class ChartSettings extends StatelessWidget {
  const ChartSettings({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    SettingsModel settings = Provider.of<SettingsModel>(context);

    final List<DropdownMenuItem<ChartMode>> chartModeItems =
        ChartMode.values.map((ChartMode mode) {
      return DropdownMenuItem<ChartMode>(
        value: mode,
        child: Text(
          mode.name,
          style: const TextStyle(
            color: Colors.white,
          ),
        ),
      );
    }).toList();

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: DropdownButton(
          isDense: true,
          items: chartModeItems,
          value: settings.chartMode,
          dropdownColor: Colors.blueGrey,
          style: const TextStyle(color: Colors.white),
          iconEnabledColor: Colors.white,
          onChanged: (ChartMode? mode) {
            if (mode != null) {
              settings.setChartMode(mode);
            }
          },
        ),
      ),
    );
  }
}

class MainScreen extends HookWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    ValueNotifier<int> screen = useState(0);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'SCI Movement',
          style: AppTheme.appBarTextStyle,
        ),
        actions: [
          if (screen.value == 0) const ChartSettings(),
        ],
      ),
      body: _page(screen.value),
      bottomNavigationBar: BottomNavigationBar(
        elevation: 12,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        currentIndex: screen.value,
        selectedItemColor: Colors.blueGrey[800],
        onTap: (index) {
          screen.value = index;
        },
      ),
    );
  }

  _page(int index) {
    switch (index) {
      case 0:
        return HomeScreen();
      case 1:
        return SettingsScreen();
      default:
        return HomeScreen();
    }
  }
}

class HomeScreen extends StatelessWidget {
  HomeScreen({Key? key}) : super(key: key);
  final RefreshController _refreshController =
      RefreshController(initialRefresh: true);

  @override
  Widget build(BuildContext context) {
    ActivityModel activityModel = Provider.of<ActivityModel>(context);
    EnergyModel energyModel = Provider.of<EnergyModel>(context);
    PushModel pushModel = Provider.of<PushModel>(context);

    return SmartRefresher(
      controller: _refreshController,
      onRefresh: () async {
        if (pushModel.shouldAsk) {
          await pushModel.requestPermission();
        }
        await activityModel.getHeartRates();
        await energyModel.getEnergy();
        _refreshController.refreshCompleted();
      },
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        children: [
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
          Center(child: Text('Heartrate', style: AppTheme.titleTextStyle)),
          const SizedBox(height: 8),
          HeartRateChart(
            heartRates: activityModel.heartRates,
            from: activityModel.from,
            to: activityModel.to,
          ),
          const SizedBox(
            height: 12,
          ),
          const EnergyDisplay(),
        ],
      ),
    );
  }
}
