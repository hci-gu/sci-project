import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:scimovement/api/classes.dart';
import 'package:scimovement/models/journal.dart';
import 'package:scimovement/screens/journal/widgets/pain_level_form.dart';
import 'package:scimovement/screens/journal/widgets/pressure_release_form.dart';
import 'package:scimovement/screens/journal/widgets/pressure_ulcer_form.dart';
import 'package:scimovement/theme/theme.dart';
import 'package:scimovement/widgets/button.dart';
import 'package:scimovement/widgets/text_field.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class EditJournalEntryScreen extends ConsumerWidget {
  final bool shouldCreateEntry;
  final JournalType? type;
  final JournalEntry? entry;

  const EditJournalEntryScreen(
      {Key? key, this.entry, this.type, this.shouldCreateEntry = true})
      : super(key: key);

  FormGroup buildForm() {
    Map<String, FormControl> defaultFields = {
      'time': FormControl<DateTime>(
        value:
            shouldCreateEntry ? DateTime.now() : entry?.time ?? DateTime.now(),
        validators: [Validators.required],
      ),
      'comment': FormControl<String>(
        value: entry?.comment ?? '',
      ),
    };

    return fb.group({
      ...defaultFields,
      if (entry is PainLevelEntry || type == JournalType.pain)
        ...PainLevelForm.buildForm(entry as PainLevelEntry?),
      if (entry is PressureReleaseEntry || type == JournalType.pressureRelease)
        ...PressureReleaseForm.buildForm(
            entry as PressureReleaseEntry?, shouldCreateEntry),
      if (entry is PressureUlcerEntry || type == JournalType.pressureUlcer)
        ...PressureUlcerForm.buildForm(
            entry as PressureUlcerEntry?, shouldCreateEntry)
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
              StyledTextField(
                formControlName: 'comment',
                placeholder:
                    AppLocalizations.of(context)!.painCommentPlaceholder,
                helperText: AppLocalizations.of(context)!.painCommentHelper,
                maxLines: 3,
              ),
              AppTheme.spacer2x,
              _submitButton(ref),
            ],
          );
        },
      ),
    );
  }

  Widget _typeSpecificForm(FormGroup form) {
    if (entry is PainLevelEntry || type == JournalType.pain) {
      return PainLevelForm(form: form, entry: entry as PainLevelEntry?);
    }
    if (entry is PressureReleaseEntry || type == JournalType.pressureRelease) {
      return PressureReleaseForm(form: form);
    }
    if (entry is PressureUlcerEntry || type == JournalType.pressureUlcer) {
      return PressureUlcerForm(
        form: form,
        entry: entry as PressureUlcerEntry?,
        shouldCreateEntry: shouldCreateEntry,
      );
    }

    return Container();
  }

  Widget _submitButton(WidgetRef ref) {
    return ReactiveFormConsumer(
      builder: ((context, form, child) => Button(
            width: 160,
            disabled: !form.valid,
            onPressed: () async {
              if (shouldCreateEntry) {
                await ref
                    .read(updateJournalProvider.notifier)
                    .createJournalEntry(entry?.type ?? type!, form.value);
              } else {
                await ref
                    .read(updateJournalProvider.notifier)
                    .updateJournalEntry(entry!, form.value);
              }
              form.reset();
              if (context.mounted) {
                while (context.canPop()) {
                  context.pop();
                }
              }
            },
            title: shouldCreateEntry
                ? AppLocalizations.of(context)!.save
                : AppLocalizations.of(context)!.update,
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
        title:
            DateFormat('yyyy-MM-dd HH:mm').format(form.control(formKey).value),
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
