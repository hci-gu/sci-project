import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:scimovement/theme/theme.dart';
import 'package:scimovement/widgets/energy_display.dart';

class MeasureScreen extends HookWidget {
  const MeasureScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    useEffect(() {
      return () => {};
    }, []);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          EnergyDisplay(),
          TextButton.icon(
            style: AppTheme.buttonStyle,
            onPressed: () {},
            icon: const Icon(Icons.timer, color: Colors.white),
            label: Text(
              'Start',
              style: AppTheme.buttonTextStyle,
            ),
          ),
        ],
      ),
    );
  }
}
