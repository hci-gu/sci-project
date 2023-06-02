import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scimovement/api/api.dart';
import 'package:scimovement/api/classes.dart';
import 'package:scimovement/models/bouts.dart';
import 'package:scimovement/models/energy.dart';
import 'package:scimovement/models/pagination.dart';
import 'package:scimovement/theme/theme.dart';
import 'package:scimovement/widgets/button.dart';
import 'package:scimovement/widgets/duration_picker.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class AddExcercise extends HookConsumerWidget {
  final Function callback;

  const AddExcercise({Key? key, required this.callback}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ValueNotifier<Activity?> activity = useState(null);
    ValueNotifier<TimeOfDay> time = useState(TimeOfDay.now());
    ValueNotifier<Duration> duration = useState(Duration.zero);

    return Container(
      width: MediaQuery.of(context).size.width,
      padding: EdgeInsets.all(AppTheme.basePadding * 2),
      height: 360,
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text(
            '${AppLocalizations.of(context)!.register} ${AppLocalizations.of(context)!.workout.toLowerCase()}',
            style: AppTheme.headLine3,
          ),
          AppTheme.spacer2x,
          ActivitySelect(
            value: activity.value,
            onChanged: (Activity? value) {
              activity.value = value;
            },
          ),
          AppTheme.spacer2x,
          Text('${AppLocalizations.of(context)!.startTime}:',
              style: AppTheme.labelLarge),
          Button(
            width: 150,
            title:
                '${AppLocalizations.of(context)!.change} ${time.value.format(context)}',
            size: ButtonSize.small,
            onPressed: () async {
              TimeOfDay? selectedTime = await showTimePicker(
                initialTime: time.value,
                context: context,
              );
              if (selectedTime != null) {
                time.value = selectedTime;
              }
            },
          ),
          AppTheme.spacer2x,
          Text('${AppLocalizations.of(context)!.length}:',
              style: AppTheme.labelLarge),
          DurationPicker(
            value: duration.value,
            onChange: (value) {
              duration.value = value;
            },
          ),
          AppTheme.separator,
          Center(
            child: Button(
              width: 200,
              disabled: activity.value == null,
              onPressed: () async {
                DateTime date = DateTime(
                  DateTime.now().year,
                  DateTime.now().month,
                  DateTime.now().day,
                  time.value.hour,
                  time.value.minute,
                );
                await Api().createBout(
                  date,
                  duration.value.inMinutes,
                  activity.value!,
                );
                ref.invalidate(boutsProvider(const Pagination()));
                ref.invalidate(energyProvider(const Pagination()));
                ref.invalidate(excerciseBoutsProvider(const Pagination()));
                callback();
              },
              title: AppLocalizations.of(context)!.add,
            ),
          )
        ],
      ),
    );
  }
}

class ActivitySelect extends StatelessWidget {
  final Activity? value;
  final Function onChanged;

  const ActivitySelect({
    Key? key,
    this.value,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.colors.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4.0),
        child: DropdownButton<Activity>(
          isDense: true,
          items: Activity.values
              .where((e) => e.isExercise)
              .map(
                (e) => DropdownMenuItem(
                  value: e,
                  child: Text(e.displayString(context)),
                ),
              )
              .toList(),
          onChanged: (value) => onChanged(value),
          style: AppTheme.labelLarge.copyWith(color: AppTheme.colors.white),
          icon: Icon(Icons.keyboard_arrow_down, color: AppTheme.colors.white),
          dropdownColor: AppTheme.colors.primary,
          borderRadius: BorderRadius.circular(16),
          underline: Container(),
          hint: Text(
            '${AppLocalizations.of(context)!.select} ${AppLocalizations.of(context)!.activity.toLowerCase()}',
            style: AppTheme.labelTiny.copyWith(color: AppTheme.colors.white),
          ),
          value: value,
        ),
      ),
    );
  }
}
