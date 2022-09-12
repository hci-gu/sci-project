import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:scimovement/models/activity.dart';
import 'package:scimovement/models/config.dart';
import 'package:scimovement/screens/settings.dart';
import 'package:scimovement/theme/theme.dart';
import 'package:scimovement/widgets/activity_wheel/activity_wheel.dart';
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
        elevation: 1,
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

final energyWidgetProvider = FutureProvider<WidgetValues>((ref) async {
  int current = await ref.watch(totalEnergyProvider(const Pagination()).future);
  int previous = await ref.watch(totalEnergyProvider(
          const Pagination(page: 1, duration: Duration(days: 1)))
      .future);
  return WidgetValues(current, previous);
});

class HomeScreen extends ConsumerWidget {
  HomeScreen({Key? key}) : super(key: key);
  final RefreshController _refreshController =
      RefreshController(initialRefresh: true);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SmartRefresher(
      controller: _refreshController,
      onRefresh: () async {
        ref.read(dateProvider.notifier).state = DateTime.now();
        _refreshController.refreshCompleted();
      },
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        children: [
          const DateSelect(),
          const SizedBox(height: 32),
          const ActivityWheel(),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ref.watch(energyWidgetProvider).when(
                    data: (WidgetValues values) => GestureDetector(
                      onTap: () => context.goNamed('calories'),
                      child: StatWidget(
                        values: values,
                        unit: Unit.calories,
                        asset: 'assets/svg/flame.svg',
                      ),
                    ),
                    error: (_, __) => Container(),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                  ),
              // StatWidget(
              //   value: energyModel.minutesInactive,
              //   oldValue: energyModel.prevMinutesInactive,
              //   unit: Unit.sedentary,
              //   asset: 'assets/svg/wheelchair.svg',
              // ),
            ],
          ),
        ],
      ),
    );
  }
}
