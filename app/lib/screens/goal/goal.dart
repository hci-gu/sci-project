import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:scimovement/models/goals.dart';
import 'package:scimovement/models/journal.dart';
import 'package:scimovement/screens/journal/widgets/pain_slider.dart';
import 'package:scimovement/theme/theme.dart';
import 'package:scimovement/widgets/button.dart';
import 'package:scimovement/widgets/text_field.dart';

class GoalScreen extends ConsumerWidget {
  final Goal? goal;

  const GoalScreen({this.goal, super.key});

  FormGroup buildForm() => fb.group({
        'value': FormControl<int>(
          value: goal?.value ?? 0,
          validators: [
            Validators.required,
            Validators.min(0),
            Validators.max(20)
          ],
        ),
        'start': FormControl<Duration>(
          value: goal?.start != null ? goal!.start : Duration.zero,
          validators: [Validators.required],
        ),
      });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppTheme.appBar('Mål'),
      body: ReactiveFormBuilder(
        form: buildForm,
        builder: (context, form, _) {
          return ListView(
            padding: AppTheme.screenPadding,
            children: [
              Center(
                child: SizedBox(
                  height: 128,
                  child: SvgPicture.asset('assets/svg/set_goal.svg'),
                ),
              ),
              Text(
                'Sätt ditt dagliga mål för avlastning',
                textAlign: TextAlign.center,
                style: AppTheme.headLine3,
              ),
              AppTheme.spacer2x,
              _textSection(
                'Hur många gånger per dag?',
                'Vi rekommenderar 6 gånger om dagen.',
              ),
              AppTheme.spacer2x,
              const StyledTextField(
                formControlName: 'value',
                placeholder: 'Välj ett nummer',
                keyboardType: TextInputType.number,
              ),
              AppTheme.spacer2x,
              _textSection(
                'Vilken tid på dagen vill du börja?',
                'T.ex. en timme efter att du brukar vakna.',
              ),
              AppTheme.spacer2x,
              ReactiveFormConsumer(
                builder: (context, formGroup, child) {
                  return DurationPicker(
                    value: formGroup.value['start'] as Duration,
                    onChange: (value) {
                      formGroup.patchValue({
                        'start': value,
                      });
                    },
                  );
                },
              ),
              AppTheme.spacer4x,
              _saveButton(ref),
            ],
          );
        },
      ),
    );
  }

  Widget _saveButton(WidgetRef ref) {
    return ReactiveFormConsumer(
      builder: (context, form, __) => Center(
        child: Button(
          disabled: form.valid == false,
          width: 180,
          title: 'Spara',
          onPressed: () async {
            if (goal != null) {
              Duration start = form.value['start'] as Duration;
              await ref.read(updateGoalProvider.notifier).updateGoal(
                    Goal(
                      id: goal!.id,
                      value: form.value['value'] as int,
                      start: start,
                      progress: 0,
                      recurrence: Duration.zero,
                      reminder: DateTime.now(),
                    ),
                  );
            } else {
              await ref
                  .read(updateGoalProvider.notifier)
                  .createGoal(form.value);
            }
            if (context.mounted) {
              context.pop();
            }
          },
        ),
      ),
    );
  }

  Widget _textSection(String title, String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTheme.labelLarge),
        Text(description, style: AppTheme.paragraphMedium)
      ],
    );
  }
}

class DurationPicker extends HookWidget {
  final String? title;
  final Color? titleColor;
  final Duration value;
  final Function onChange;
  final bool readOnly;

  const DurationPicker({
    Key? key,
    required this.value,
    required this.onChange,
    this.title,
    this.titleColor,
    this.readOnly = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    FocusNode focusNode = useFocusNode();

    return Padding(
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
              _showDurationPicker(context);
            },
            child: DurationDisplay(
              duration: value,
              highlighted: focusNode.hasFocus,
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Button(
                  title: 'Stäng',
                  onPressed: () {
                    Navigator.pop(ctx);
                    FocusScope.of(context).unfocus();
                  },
                  width: 100,
                  size: ButtonSize.small,
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
      clipBehavior: Clip.none,
      width: 90,
      height: 50,
      child: Padding(
        padding: AppTheme.elementPadding,
        child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text(
                hours.length == 1 ? '0$hours' : hours,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Text(':'),
              Text(
                minutes,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ]),
      ),
    );
  }
}
