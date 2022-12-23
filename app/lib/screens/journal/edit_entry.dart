import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:scimovement/api/classes.dart';
import 'package:scimovement/models/journal.dart';
import 'package:scimovement/screens/journal/widgets/body_part_select.dart';
import 'package:scimovement/screens/journal/widgets/pain_slider.dart';
import 'package:scimovement/theme/theme.dart';
import 'package:scimovement/widgets/button.dart';
import 'package:scimovement/widgets/text_field.dart';

class EditJournalEntryScreen extends ConsumerWidget {
  final BodyPart? bodyPart;
  final JournalEntry? entry;

  const EditJournalEntryScreen({
    Key? key,
    this.bodyPart,
    this.entry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    BodyPart? initialBodyPart = entry != null ? entry!.bodyPart : bodyPart;
    return Scaffold(
      appBar: AppTheme.appBar(
          initialBodyPart?.displayString() ?? 'Lägg till kroppsdel'),
      body: ListView(
        padding: AppTheme.screenPadding,
        children: [
          EditJournalEntry(
            initialBodyPart: initialBodyPart,
            existingEntry: entry,
          ),
        ],
      ),
    );
  }
}

class EditJournalEntry extends ConsumerWidget {
  final BodyPart? initialBodyPart;
  final JournalEntry? existingEntry;

  const EditJournalEntry({
    Key? key,
    this.initialBodyPart,
    this.existingEntry,
  }) : super(key: key);

  FormGroup buildForm() => fb.group({
        'bodyPartType': FormControl<BodyPartType>(
          value: initialBodyPart?.type,
          validators: [Validators.required],
        ),
        'side': FormControl<Side>(
          value: initialBodyPart?.side ?? Side.right,
          validators: [Validators.required],
        ),
        'painLevel': FormControl<int>(
          value: existingEntry?.painLevel ?? 1,
          validators: [
            Validators.required,
            Validators.min(1),
            Validators.max(10)
          ],
        ),
        'comment': FormControl<String>(
          value: existingEntry?.comment ?? '',
        ),
      });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ReactiveFormBuilder(
      form: buildForm,
      builder: (context, form, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (initialBodyPart == null) BodyPartSelect(form: form),
            if (initialBodyPart == null) AppTheme.spacer2x,
            Text('Smärtnivå', style: AppTheme.labelLarge),
            Text(
              'Välj ett nummer mellan 1-10',
              style: AppTheme.paragraphMedium,
            ),
            AppTheme.spacer2x,
            PainSlider(formKey: 'painLevel'),
            AppTheme.spacer2x,
            Text('Kommentar ( valfri )', style: AppTheme.labelLarge),
            AppTheme.spacer,
            const StyledTextField(
              formControlName: 'comment',
              placeholder: 'Skriv en kommentar',
              helperText:
                  'Beskriv hur du mår, vad du har gjort, hur du har sovit etc.',
              maxLines: 3,
            ),
            AppTheme.spacer2x,
            ReactiveFormConsumer(
              builder: ((context, form, child) => Button(
                    width: 160,
                    disabled: !form.valid,
                    onPressed: () async {
                      if (existingEntry != null) {
                        await ref
                            .read(updateJournalProvider.notifier)
                            .updateJournalEntry(existingEntry!, form.value);
                      } else {
                        await ref
                            .read(updateJournalProvider.notifier)
                            .createJournalEntry(form.value);
                      }

                      form.reset();
                      GoRouter.of(context).pop();
                    },
                    title: existingEntry != null ? 'Uppdatera' : 'Spara',
                  )),
            ),
          ],
        );
      },
    );
  }
}
