import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:scimovement/models/activity.dart';
import 'package:scimovement/models/energy.dart';
import 'package:scimovement/models/push.dart';
import 'package:scimovement/screens/settings.dart';
import 'package:scimovement/theme/theme.dart';
import 'package:scimovement/widgets/date_select.dart';
import 'package:scimovement/widgets/energy_display.dart';
import 'package:scimovement/widgets/stat_widget.dart';
import 'package:go_router/go_router.dart';

class MainScreen extends HookWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    ValueNotifier<int> screen = useState(0);

    return Scaffold(
      body: SafeArea(
        child: _page(screen.value),
      ),
      bottomNavigationBar: BottomNavigationBar(
        elevation: 4,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Hem',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            label: 'Inställningar',
          ),
        ],
        currentIndex: screen.value,
        selectedItemColor: AppTheme.colors.primary,
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
          const DateSelect(),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => context.goNamed('calories'),
                child: StatWidget(
                  value: energyModel.energyTotal.toInt(),
                  oldValue: energyModel.prevTotal.toInt(),
                  unit: Unit.calories,
                  asset: 'assets/svg/flame.svg',
                ),
              ),
              StatWidget(
                value: energyModel.minutesInactive,
                oldValue: energyModel.prevMinutesInactive,
                unit: Unit.sedentary,
                asset: 'assets/svg/wheelchair.svg',
              ),
            ],
          ),
          const SizedBox(height: 16),
          const EnergyDisplay(),
        ],
      ),
    );
  }
}
