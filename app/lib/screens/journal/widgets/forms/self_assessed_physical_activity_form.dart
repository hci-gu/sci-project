import 'package:flutter/material.dart';
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
  })  : _entry = entry,
        _shouldCreateEntry = shouldCreateEntry;

  final FormGroup form;
  // ignore: unused_field
  final SelfAssessedPhysicalActivityEntry? _entry;
  // ignore: unused_field
  final bool _shouldCreateEntry;

  static const String _stepControl = 'sapStep';

  static const int _pageCount = 3;

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
            Center(
              child: StepIndicator(
                index: step,
                count: _pageCount,
              ),
            ),
            AppTheme.spacer2x,
            ..._pageContent(context, step),
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
      default:
        return _sedentaryContent(context);
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
      ...SelfAssessedPhysicalActivityDuration.values.map(
        (value) => _radioTile<SelfAssessedPhysicalActivityDuration>(
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
      ...SelfAssessedPhysicalActivityDuration.values.map(
        (value) => _radioTile<SelfAssessedPhysicalActivityDuration>(
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
          value: value,
          groupValue: control.value,
          onChanged: (selected) {
            if (selected != null) {
              form.control(groupControlName).value = selected;
            }
          },
          title: Text(
            label,
            style: AppTheme.labelLarge,
          ),
        );
      },
    );
  }

  static Widget actions(
    BuildContext context,
    FormGroup form,
    Function callback,
  ) {
    return ReactiveValueListenableBuilder<int>(
      formControlName: _stepControl,
      builder: (context, control, _) {
        final l10n = AppLocalizations.of(context)!;
        final int step = control.value ?? 0;
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (step > 0)
              Button(
                width: 120,
                secondary: true,
                onPressed: () {
                  form.control(_stepControl).value = step - 1;
                },
                title: l10n.back,
              )
            else
              const SizedBox(width: 120),
            if (step < _pageCount - 1)
              Button(
                width: 120,
                disabled: !_isStepComplete(form, step),
                onPressed: () {
                  form.control(_stepControl).value = step + 1;
                },
                title: l10n.next,
              )
            else
              Button(
                width: 160,
                disabled: !form.valid,
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
        return form.control('trainingDuration').valid;
      case 1:
        return form.control('everydayActivityDuration').valid;
      default:
        return false;
    }
  }

  static Map<String, FormControl> buildForm(
    SelfAssessedPhysicalActivityEntry? entry,
    bool shouldCreateEntry,
  ) {
    return {
      'trainingDuration': FormControl<SelfAssessedPhysicalActivityDuration>(
        value: entry?.trainingDuration,
        validators: [Validators.required],
      ),
      'everydayActivityDuration':
          FormControl<SelfAssessedPhysicalActivityDuration>(
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
