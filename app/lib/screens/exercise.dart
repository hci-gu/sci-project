import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scimovement/api/api.dart';
import 'package:scimovement/api/classes.dart';
import 'package:scimovement/models/bouts.dart';
import 'package:scimovement/models/energy.dart';
import 'package:scimovement/models/pagination.dart';
import 'package:scimovement/theme/theme.dart';
import 'package:scimovement/widgets/button.dart';
import 'package:scimovement/widgets/editable_list_item.dart';

class ExcerciseScreen extends HookConsumerWidget {
  final bool startWithAdd;

  const ExcerciseScreen({
    Key? key,
    this.startWithAdd = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ValueNotifier<bool> isOpened = useState(startWithAdd);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Träning'),
      ),
      floatingActionButton: Builder(builder: (context) {
        return AddExerciseButton(
          isOpened: isOpened.value,
          callback: () {
            isOpened.value = !isOpened.value;
          },
        );
      }),
      body: ref.watch(excerciseBoutsProvider).when(
            data: (data) => _body(ref, data),
            error: (_, __) => Container(),
            loading: () => const Center(
              child: CircularProgressIndicator(),
            ),
          ),
    );
  }

  Widget _body(WidgetRef ref, List<Bout> bouts) {
    return ListView.builder(
      itemCount: bouts.length,
      itemBuilder: (context, index) {
        return EditableListItem(
          id: bouts[index].time.toString(),
          title: bouts[index].activity.displayString(),
          subtitle: bouts[index].displayDuration,
          onDismissed: () async {
            await Api().deleteBout(bouts[index].id);
            ref.refresh(boutsProvider(const Pagination()));
            ref.refresh(energyProvider(const Pagination()));
            ref.refresh(excerciseBoutsProvider);
          },
          onTap: () {},
        );
      },
    );
  }
}

class AddExerciseButton extends HookWidget {
  final bool isOpened;
  final Function callback;

  const AddExerciseButton(
      {Key? key, required this.isOpened, required this.callback})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    useEffect(() {
      if (isOpened) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _openBottomSheet(context);
        });
      }
      return () {};
    });

    return FloatingActionButton(
      onPressed: () {
        if (isOpened) {
          Navigator.pop(context);
        } else {
          _openBottomSheet(context);
        }
        callback();
      },
      child: isOpened ? const Icon(Icons.close) : const Icon(Icons.add),
    );
  }

  void _openBottomSheet(BuildContext context) {
    showBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
      ),
      elevation: 4,
      clipBehavior: Clip.hardEdge,
      builder: (context) => AddExcercise(
        callback: () {
          Navigator.pop(context);
          callback();
        },
      ),
    );
  }
}

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
      height: 400,
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text('Registrera Träningspass', style: AppTheme.headLine3),
          AppTheme.spacer2x,
          ActivitySelect(
            value: activity.value,
            onChanged: (Activity? value) {
              activity.value = value;
            },
          ),
          AppTheme.spacer2x,
          Text('Starttid:', style: AppTheme.labelLarge),
          Button(
            width: 150,
            title: 'Ändra ${time.value.format(context)}',
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
          Text('Längd:', style: AppTheme.labelLarge),
          DurationPickerRow(
            value: duration.value,
            onChange: (value) {
              duration.value = value;
            },
          ),
          AppTheme.spacer2x,
          Button(
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

              ref.refresh(boutsProvider(const Pagination()));
              ref.refresh(energyProvider(const Pagination()));
              ref.refresh(excerciseBoutsProvider);
              callback();
            },
            title: 'Lägg till',
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
              .map((e) =>
                  DropdownMenuItem(child: Text(e.displayString()), value: e))
              .toList(),
          onChanged: (value) => onChanged(value),
          style: AppTheme.labelLarge.copyWith(color: AppTheme.colors.white),
          icon: Icon(Icons.keyboard_arrow_down, color: AppTheme.colors.white),
          dropdownColor: AppTheme.colors.primary,
          borderRadius: BorderRadius.circular(16),
          underline: Container(),
          hint: Text(
            'Välj aktivitet',
            style: AppTheme.labelTiny.copyWith(color: AppTheme.colors.white),
          ),
          value: value,
        ),
      ),
    );
  }
}

class DurationPickerRow extends HookWidget {
  final String? title;
  final Color? titleColor;
  final Duration value;
  final Function onChange;
  final bool readOnly;

  const DurationPickerRow({
    Key? key,
    required this.value,
    required this.onChange,
    this.title,
    this.titleColor,
    this.readOnly = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    FocusNode _focusNode = useFocusNode();

    return Focus(
      focusNode: _focusNode,
      onFocusChange: (focused) {
        if (focused && !readOnly) {
          _showDurationPicker(context);
          onChange(value);
          Scrollable.ensureVisible(
            _focusNode.context!,
            duration: const Duration(milliseconds: 250),
          );
        }
      },
      child: Padding(
        padding: EdgeInsets.only(top: AppTheme.basePadding * 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            if (title != null) _title(context),
            Button(
              width: 34,
              icon: Icons.remove,
              onPressed: () {
                if (value.inMinutes >= 15) {
                  onChange(Duration(minutes: value.inMinutes - 15));
                }
              },
              disabled: readOnly,
              size: ButtonSize.small,
            ),
            AppTheme.spacer,
            GestureDetector(
              onTap: () {
                if (readOnly) return;
                _focusNode.requestFocus();
              },
              child: DurationDisplay(
                duration: value,
                highlighted: _focusNode.hasFocus,
              ),
            ),
            AppTheme.spacer,
            Button(
              width: 34,
              icon: Icons.add,
              onPressed: () {
                onChange(Duration(minutes: value.inMinutes + 15));
              },
              size: ButtonSize.small,
              disabled: readOnly,
            ),
          ],
        ),
      ),
    );
  }

  Widget _title(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            title!,
            style: const TextStyle(fontSize: 16),
          ),
        ),
        const SizedBox(height: 2),
        SizedBox(
          width: 30,
          height: 3,
          child: Container(color: titleColor ?? AppTheme.colors.primary),
        )
      ],
    );
  }

  void _showDurationPicker(BuildContext context) {
    showBottomSheet(
      elevation: 24,
      context: context,
      builder: (BuildContext ctx) {
        return Container(
          height: 275,
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.black.withAlpha(100),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: AppTheme.elementPadding,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Button(
                      title: 'Stäng',
                      onPressed: () {
                        Navigator.pop(ctx);
                      },
                      width: 100,
                      size: ButtonSize.small,
                    ),
                  ],
                ),
                CupertinoTimerPicker(
                  initialTimerDuration: value,
                  mode: CupertinoTimerPickerMode.hm,
                  minuteInterval: 15,
                  onTimerDurationChanged: (value) {
                    onChange(value);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class DurationDisplay extends StatelessWidget {
  final Duration duration;
  final bool highlighted;

  const DurationDisplay({
    Key? key,
    required this.duration,
    this.highlighted = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String hours = duration.toString().split(':')[0];
    String minutes = duration.toString().split(':')[1];

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: highlighted ? AppTheme.colors.primaryDark : Colors.black,
          width: highlighted ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      width: 80,
      height: 40,
      child: Padding(
        padding: AppTheme.elementPadding,
        child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text(
                hours.length == 1 ? '0$hours' : hours,
                style: AppTheme.labelMedium,
              ),
              const Text(':'),
              Text(
                minutes,
                style: AppTheme.labelMedium,
              ),
            ]),
      ),
    );
  }
}
