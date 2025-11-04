import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:scimovement/api/classes/journal/journal.dart';
import 'package:scimovement/gen_l10n/app_localizations.dart';
import 'package:scimovement/screens/onboarding/widgets/onboarding_stepper.dart';
import 'package:scimovement/theme/theme.dart';
import 'package:scimovement/widgets/button.dart';

class SelfAssessedPhysicalActivityForm extends StatelessWidget {
  const SelfAssessedPhysicalActivityForm({
    super.key,
    required this.form,
    SelfAssessedPhysicalActivityEntry? entry,
    bool shouldCreateEntry = true,
  }) : _entry = entry,
       _shouldCreateEntry = shouldCreateEntry;

  final FormGroup form;
  // ignore: unused_field
  final SelfAssessedPhysicalActivityEntry? _entry;
  // ignore: unused_field
  final bool _shouldCreateEntry;

  static const String _stepControl = 'sapStep';

  static const int _pageCount = 4;

  static String get stepControlName => _stepControl;

  @override
  Widget build(BuildContext context) {
    return ReactiveValueListenableBuilder<int>(
      formControlName: _stepControl,
      builder: (context, control, _) {
        final int step = control.value ?? 0;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ..._pageContent(context, step),
            AppTheme.spacer2x,
            if (step < 3)
              Center(child: StepIndicator(index: step, count: _pageCount)),
          ],
        );
      },
    );
  }

  List<Widget> _pageContent(BuildContext context, int step) {
    switch (step) {
      case 0:
        return _trainingContent(context);
      case 1:
        return _everydayActivityContent(context);
      case 2:
        return _sedentaryContent(context);
      default:
        return _weekInformationContent(context);
    }
  }

  List<Widget> _trainingContent(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return [
      Text(
        l10n.selfAssessedPhysicalActivityTrainingTitle,
        style: AppTheme.headLine3,
      ),
      AppTheme.spacer,
      Text(
        l10n.selfAssessedPhysicalActivityTrainingDescription,
        style: AppTheme.paragraphMedium,
      ),
      AppTheme.spacer2x,
      ...SelfAssessedPhysicalActivityTrainingDuration.values.map(
        (value) => _radioTile<SelfAssessedPhysicalActivityTrainingDuration>(
          context: context,
          value: value,
          groupControlName: 'trainingDuration',
          label: value.displayString(context),
        ),
      ),
    ];
  }

  List<Widget> _everydayActivityContent(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return [
      Text(
        l10n.selfAssessedPhysicalActivityEverydayTitle,
        style: AppTheme.headLine3,
      ),
      AppTheme.spacer,
      Text(
        l10n.selfAssessedPhysicalActivityEverydayDescription,
        style: AppTheme.paragraphMedium,
      ),
      AppTheme.spacer2x,
      ...SelfAssessedPhysicalActivityEverydayDuration.values.map(
        (value) => _radioTile<SelfAssessedPhysicalActivityEverydayDuration>(
          context: context,
          value: value,
          groupControlName: 'everydayActivityDuration',
          label: value.displayString(context),
        ),
      ),
    ];
  }

  List<Widget> _sedentaryContent(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return [
      Text(
        l10n.selfAssessedPhysicalActivitySedentaryTitle,
        style: AppTheme.headLine3,
      ),
      AppTheme.spacer,
      Text(
        l10n.selfAssessedPhysicalActivitySedentaryDescription,
        style: AppTheme.paragraphMedium,
      ),
      AppTheme.spacer2x,
      ...SelfAssessedSedentaryDuration.values.map(
        (value) => _radioTile<SelfAssessedSedentaryDuration>(
          context: context,
          value: value,
          groupControlName: 'sedentaryDuration',
          label: value.displayString(context),
        ),
      ),
    ];
  }

  Widget _radioTile<T>({
    required BuildContext context,
    required T value,
    required String groupControlName,
    required String label,
  }) {
    return ReactiveValueListenableBuilder<T?>(
      formControlName: groupControlName,
      builder: (context, control, _) {
        return RadioListTile<T>(
          contentPadding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          value: value,
          groupValue: control.value,
          onChanged: (selected) {
            if (selected != null) {
              form.control(groupControlName).value = selected;
            }
          },
          title: Text(label, style: AppTheme.labelLarge),
        );
      },
    );
  }

  List<Widget> _weekInformationContent(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final timeControl = form.control('time') as FormControl<DateTime>;
    final DateTime selectedDate = timeControl.value ?? DateTime.now();
    final int daysFromMonday = selectedDate.weekday - DateTime.monday;
    final DateTime weekStart = selectedDate.subtract(
      Duration(days: daysFromMonday),
    );
    final DateTime weekEnd = weekStart.add(const Duration(days: 6));
    final dateFormatter = DateFormat('EEEE d MMMM', l10n.localeName);
    final String startText = dateFormatter.format(weekStart);
    final String endText = dateFormatter.format(weekEnd);

    return [
      Text(
        l10n.selfAssessedPhysicalActivityWeekInfoInstruction,
        style: AppTheme.paragraphMedium,
      ),
      AppTheme.spacer,
      Text(
        l10n.selfAssessedPhysicalActivityWeekInfoRange(startText, endText),
        style: AppTheme.paragraphMedium,
      ),
    ];
  }

  static Widget actions(
    BuildContext context,
    FormGroup form,
    Function callback,
  ) {
    return ReactiveFormConsumer(
      builder: (context, formGroup, _) {
        final l10n = AppLocalizations.of(context)!;
        final int step = formGroup.control(_stepControl).value as int? ?? 0;
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (step > 0)
              Button(
                width: 120,
                secondary: true,
                onPressed: () {
                  formGroup.control(_stepControl).value = step - 1;
                },
                title: l10n.back,
              )
            else
              const SizedBox(width: 120),
            if (step < _pageCount - 1)
              Button(
                width: 120,
                disabled: !_isStepComplete(formGroup, step),
                onPressed: () {
                  formGroup.control(_stepControl).value = step + 1;
                },
                title: l10n.next,
              )
            else
              Button(
                width: 160,
                disabled: !formGroup.valid,
                onPressed: () {
                  callback(true, true);
                },
                title: l10n.save,
              ),
          ],
        );
      },
    );
  }

  static bool _isStepComplete(FormGroup form, int step) {
    switch (step) {
      case 0:
        return _controlHasValue<SelfAssessedPhysicalActivityTrainingDuration>(
          form,
          'trainingDuration',
        );
      case 1:
        return _controlHasValue<SelfAssessedPhysicalActivityEverydayDuration>(
          form,
          'everydayActivityDuration',
        );
      case 2:
        return _controlHasValue<SelfAssessedSedentaryDuration>(
          form,
          'sedentaryDuration',
        );
      default:
        return false;
    }
  }

  static bool _controlHasValue<T>(FormGroup form, String controlName) {
    final control = form.control(controlName) as FormControl<T>;
    return control.value != null && control.valid;
  }

  static Map<String, FormControl> buildForm(
    SelfAssessedPhysicalActivityEntry? entry,
    bool shouldCreateEntry,
  ) {
    return {
      'trainingDuration':
          FormControl<SelfAssessedPhysicalActivityTrainingDuration>(
            value: entry?.trainingDuration,
            validators: [Validators.required],
          ),
      'everydayActivityDuration':
          FormControl<SelfAssessedPhysicalActivityEverydayDuration>(
            value: entry?.everydayActivityDuration,
            validators: [Validators.required],
          ),
      'sedentaryDuration': FormControl<SelfAssessedSedentaryDuration>(
        value: entry?.sedentaryDuration,
        validators: [Validators.required],
      ),
      _stepControl: FormControl<int>(value: 0),
    };
  }
}
