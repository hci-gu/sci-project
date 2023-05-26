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
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class EditJournalEntryScreen extends ConsumerWidget {
  final bool shouldCreateEntry;
  final JournalType? type;
  final JournalEntry? entry;

  const EditJournalEntryScreen(
      {Key? key, this.entry, this.type, this.shouldCreateEntry = true})
      : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // BodyPart? initialBodyPart = entry != null ? entry!.bodyPart : bodyPart;
    return Scaffold(
      appBar: AppTheme.appBar('test'),
      body: ListView(
        padding: AppTheme.screenPadding,
        children: [
          if (entry is PainLevelEntry || type == JournalType.pain)
            EditPainLevelEntry(
              shouldCreateEntry: shouldCreateEntry,
              initialBodyPart: (entry as PainLevelEntry?)?.bodyPart,
              existingEntry: entry as PainLevelEntry?,
            ),
        ],
      ),
    );
  }
}

class EditPainLevelEntry extends ConsumerWidget {
  final bool shouldCreateEntry;
  final BodyPart? initialBodyPart;
  final PainLevelEntry? existingEntry;

  const EditPainLevelEntry({
    Key? key,
    required this.shouldCreateEntry,
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
          value: existingEntry?.painLevel ?? 0,
          validators: [
            Validators.required,
            Validators.min(0),
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
            Text(
              AppLocalizations.of(context)!.painLevel,
              style: AppTheme.labelLarge,
            ),
            Text(
              AppLocalizations.of(context)!.painLevelHelper,
              style: AppTheme.paragraphMedium,
            ),
            AppTheme.spacer2x,
            PainSlider(formKey: 'painLevel'),
            AppTheme.spacer2x,
            Text(
                '${AppLocalizations.of(context)!.comment} ( ${AppLocalizations.of(context)!.optional} )',
                style: AppTheme.labelLarge),
            AppTheme.spacer,
            StyledTextField(
              formControlName: 'comment',
              placeholder: AppLocalizations.of(context)!.painCommentPlaceholder,
              helperText: AppLocalizations.of(context)!.painCommentHelper,
              maxLines: 3,
            ),
            AppTheme.spacer2x,
            ReactiveFormConsumer(
              builder: ((context, form, child) => Button(
                    width: 160,
                    disabled: !form.valid,
                    onPressed: () async {
                      if (shouldCreateEntry) {
                        await ref
                            .read(updateJournalProvider.notifier)
                            .createJournalEntry(form.value);
                      } else {
                        await ref
                            .read(updateJournalProvider.notifier)
                            .updateJournalEntry(existingEntry!, form.value);
                      }

                      form.reset();
                      GoRouter.of(context).pop();
                    },
                    title: existingEntry != null
                        ? AppLocalizations.of(context)!.update
                        : AppLocalizations.of(context)!.save,
                  )),
            ),
          ],
        );
      },
    );
  }
}
