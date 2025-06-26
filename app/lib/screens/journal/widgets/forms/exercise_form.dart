import 'package:flutter/material.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:scimovement/api/classes.dart';
import 'package:scimovement/api/classes/journal/exercise.dart';
import 'package:scimovement/screens/goal/goal.dart';
import 'package:scimovement/theme/theme.dart';
import 'package:scimovement/gen_l10n/app_localizations.dart';

class ExerciseForm extends StatelessWidget {
  final FormGroup form;
  final ExerciseEntry? entry;
  final bool shouldCreateEntry;

  const ExerciseForm({
    super.key,
    required this.form,
    this.entry,
    this.shouldCreateEntry = true,
  });

  @override
  Widget build(BuildContext context) {
    return ReactiveFormConsumer(
      builder: (BuildContext context, form, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.activity,
            style: AppTheme.labelLarge,
          ),
          Text(
            AppLocalizations.of(context)!.exerciseActivityDescription,
            style: AppTheme.paragraphMedium,
          ),
          AppTheme.spacer,
          ActivitySelect(
            value: form.control('activity').value,
            onChanged: (value) {
              form.control('activity').value = value;
            },
          ),
          AppTheme.spacer,
          Text(
            AppLocalizations.of(context)!.duration,
            style: AppTheme.labelLarge,
          ),
          Text(
            AppLocalizations.of(context)!.exerciseLengthDescription,
            style: AppTheme.paragraphMedium,
          ),
          Form(
            child: DurationPicker(
              value: Duration(minutes: form.control('minutes').value),
              onChange: (Duration value) {
                form.control('minutes').value = value.inMinutes;
              },
            ),
          ),
          AppTheme.spacer,
        ],
      ),
    );
  }

  static buildForm(ExerciseEntry? entry, bool shouldCreateEntry) {
    return {
      'activity': FormControl<Activity>(
        value: entry?.activity,
        validators: [Validators.required],
      ),
      'minutes': FormControl<int>(
        value: entry?.minutes ?? 0,
        validators: [Validators.min(1)],
      ),
    };
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8.0),
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
            style: AppTheme.labelMedium.copyWith(color: AppTheme.colors.white),
          ),
          value: value,
        ),
      ),
    );
  }
}
