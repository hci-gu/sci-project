import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:scimovement/api/classes/journal/bowel_emptying.dart';
import 'package:scimovement/api/classes/journal/exercise.dart';
import 'package:scimovement/api/classes/journal/journal.dart';
import 'package:scimovement/api/classes/journal/spasticity.dart';
import 'package:scimovement/models/journal/journal.dart';
import 'package:scimovement/screens/journal/widgets/forms/bladder_emptying_form.dart';
import 'package:scimovement/screens/journal/widgets/forms/bowel_emptying_form.dart';
import 'package:scimovement/screens/journal/widgets/forms/exercise_form.dart';
import 'package:scimovement/screens/journal/widgets/forms/spasticity_form.dart';
import 'package:scimovement/screens/journal/widgets/forms/uti_form.dart';
import 'package:scimovement/screens/journal/widgets/forms/pain_level_form.dart';
import 'package:scimovement/screens/journal/widgets/forms/pressure_release_form.dart';
import 'package:scimovement/screens/journal/widgets/forms/pressure_ulcer_form.dart';
import 'package:scimovement/theme/theme.dart';
import 'package:scimovement/widgets/button.dart';
import 'package:scimovement/widgets/snackbar_message.dart';
import 'package:scimovement/widgets/text_field.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class EditJournalEntryScreen extends ConsumerWidget {
  final bool shouldCreateEntry;
  final DateTime? initialDate;
  final JournalType? type;
  final JournalEntry? entry;

  const EditJournalEntryScreen({
    super.key,
    this.entry,
    this.type,
    this.initialDate,
    this.shouldCreateEntry = true,
  });

  FormGroup buildForm() {
    Map<String, FormControl> defaultFields = {
      'time': FormControl<DateTime>(
        value: shouldCreateEntry
            ? initialDate ?? DateTime.now()
            : entry?.time ?? DateTime.now(),
        validators: [Validators.required],
      ),
      'comment': FormControl<String>(
        value: entry != null && !shouldCreateEntry ? entry?.comment : '',
      ),
    };

    return fb.group({
      ...defaultFields,
      if (entry is PainLevelEntry ||
          type == JournalType.musclePain ||
          type == JournalType.neuropathicPain)
        ...PainLevelForm.buildForm(entry as PainLevelEntry?, type),
      if (entry is SpasticityEntry || type == JournalType.spasticity)
        ...SpasticityForm.buildForm(entry as SpasticityEntry?),
      if (entry is PressureReleaseEntry || type == JournalType.pressureRelease)
        ...PressureReleaseForm.buildForm(
            entry as PressureReleaseEntry?, shouldCreateEntry),
      if (entry is PressureUlcerEntry || type == JournalType.pressureUlcer)
        ...PressureUlcerForm.buildForm(
            entry as PressureUlcerEntry?, shouldCreateEntry),
      if (entry is BladderEmptyingEntry || type == JournalType.bladderEmptying)
        ...BladderEmptyingForm.buildForm(
            entry as BladderEmptyingEntry?, shouldCreateEntry),
      if (entry is BowelEmptyingEntry || type == JournalType.bowelEmptying)
        ...BowelEmptyingForm.buildForm(
            entry as BowelEmptyingEntry?, shouldCreateEntry),
      if (entry is UTIEntry || type == JournalType.urinaryTractInfection)
        ...UTIForm.buildForm(entry as UTIEntry?, shouldCreateEntry),
      if (entry is ExerciseEntry || type == JournalType.exercise)
        ...ExerciseForm.buildForm(entry as ExerciseEntry?, shouldCreateEntry)
    });
  }

  String _appBarTitle(BuildContext context) {
    if (entry != null) {
      return entry!.title(context);
    }
    if (type != null) {
      return type!.displayString(context);
    }
    return AppLocalizations.of(context)!.newEntry;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppTheme.appBar(_appBarTitle(context)),
      body: ReactiveFormBuilder(
        form: buildForm,
        builder: (context, form, _) {
          return ListView(
            padding: AppTheme.screenPadding,
            children: [
              Text(
                AppLocalizations.of(context)!.dateAndTime,
                style: AppTheme.labelLarge,
              ),
              AppTheme.spacer,
              const DateTimeButton(formKey: 'time'),
              AppTheme.spacer2x,
              _typeSpecificForm(form),
              Text(
                '${AppLocalizations.of(context)!.comment} ( ${AppLocalizations.of(context)!.optional} )',
                style: AppTheme.labelLarge,
              ),
              AppTheme.spacer,
              StyledTextField(
                formControlName: 'comment',
                placeholder:
                    AppLocalizations.of(context)!.painCommentPlaceholder,
                helperText: AppLocalizations.of(context)!.painCommentHelper,
                maxLines: 3,
              ),
              AppTheme.spacer2x,
              _actions(context, ref, form),
            ],
          );
        },
      ),
    );
  }

  Widget _actions(BuildContext context, WidgetRef ref, FormGroup form) {
    if (type == JournalType.pressureRelease ||
        (entry != null && entry!.type == JournalType.pressureRelease) &&
            shouldCreateEntry) {
      return PressureReleaseForm.actions(
        context,
        form,
        (goBack, showSnackbar) => _onSave(
          context,
          ref,
          form,
          goBack,
          showSnackbar,
        ),
      );
    }

    return _submitButton(ref);
  }

  Widget _typeSpecificForm(FormGroup form) {
    if (entry is PainLevelEntry ||
        type == JournalType.musclePain ||
        type == JournalType.neuropathicPain) {
      return PainLevelForm(
        form: form,
        type: type,
        entry: entry as PainLevelEntry?,
      );
    }
    if (entry is SpasticityEntry || type == JournalType.spasticity) {
      return SpasticityForm(
        form: form,
        entry: entry as SpasticityEntry?,
      );
    }
    if (entry is PressureReleaseEntry || type == JournalType.pressureRelease) {
      return PressureReleaseForm(
        form: form,
        shouldCreateEntry: shouldCreateEntry,
      );
    }
    if (entry is PressureUlcerEntry || type == JournalType.pressureUlcer) {
      return PressureUlcerForm(
        form: form,
        entry: entry as PressureUlcerEntry?,
        shouldCreateEntry: shouldCreateEntry,
      );
    }
    if (entry is BladderEmptyingEntry || type == JournalType.bladderEmptying) {
      return BladderEmptyingForm(
        form: form,
        entry: entry as BladderEmptyingEntry?,
        shouldCreateEntry: shouldCreateEntry,
      );
    }
    if (entry is BowelEmptyingEntry || type == JournalType.bowelEmptying) {
      return BowelEmptyingForm(
        form: form,
        entry: entry as BowelEmptyingEntry?,
        shouldCreateEntry: shouldCreateEntry,
      );
    }
    if (entry is UTIEntry || type == JournalType.urinaryTractInfection) {
      return UTIForm(
        form: form,
        entry: entry as UTIEntry?,
        shouldCreateEntry: shouldCreateEntry,
      );
    }
    if (entry is ExerciseEntry || type == JournalType.exercise) {
      return ExerciseForm(
        form: form,
        entry: entry as ExerciseEntry?,
        shouldCreateEntry: shouldCreateEntry,
      );
    }

    return Container();
  }

  Future _onSave(BuildContext context, WidgetRef ref, FormGroup form,
      [bool shouldPop = true, bool showSnackbar = true]) async {
    if (shouldCreateEntry) {
      await ref
          .read(updateJournalProvider.notifier)
          .createJournalEntry(entry?.type ?? type!, form.value);
    } else {
      await ref
          .read(updateJournalProvider.notifier)
          .updateJournalEntry(entry!, form.value);
    }
    if (context.mounted && shouldPop) {
      while (context.canPop()) {
        context.pop();
      }
    }

    if (context.mounted && showSnackbar) {
      String typeTitle = entry?.type.displayString(context) ??
          type?.displayString(context) ??
          '';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackbarMessage(
          context: context,
          message:
              '$typeTitle ${AppLocalizations.of(context)!.saved.toLowerCase()}',
          type: SnackbarType.success,
        ),
      );
    }

    form.dispose();
  }

  Widget _submitButton(WidgetRef ref) {
    return ReactiveFormConsumer(
      builder: ((context, form, child) => Center(
            child: Button(
              width: 160,
              disabled: !form.valid,
              onPressed: () => _onSave(context, ref, form),
              title: shouldCreateEntry
                  ? AppLocalizations.of(context)!.save
                  : AppLocalizations.of(context)!.update,
            ),
          )),
    );
  }
}

class DateTimeButton extends StatelessWidget {
  final String formKey;

  const DateTimeButton({
    super.key,
    required this.formKey,
  });

  @override
  Widget build(BuildContext context) {
    return ReactiveFormConsumer(
      builder: (context, form, _) => Button(
        title: DateFormat('yyyy-MM-dd HH:mm')
            .format(form.control(formKey).value ?? DateTime.now()),
        width: 160,
        icon: Icons.calendar_month_outlined,
        onPressed: () async {
          DateTime? date = await showDatePicker(
            context: context,
            initialDate: form.control(formKey).value,
            firstDate: DateTime.now().subtract(const Duration(days: 365)),
            lastDate: DateTime.now(),
          );
          if (context.mounted) {
            TimeOfDay? time = await showTimePicker(
              context: context,
              initialTime: TimeOfDay.fromDateTime(form.control(formKey).value),
            );
            if (date != null && time != null) {
              DateTime timestamp = DateTime(
                date.year,
                date.month,
                date.day,
                time.hour,
                time.minute,
              );
              form.control(formKey).value = timestamp;
            }
          }
        },
      ),
    );
  }
}
