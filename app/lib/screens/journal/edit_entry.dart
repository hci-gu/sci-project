import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:scimovement/api/classes.dart';
import 'package:scimovement/models/journal.dart';
import 'package:scimovement/screens/journal/widgets/body_part_select.dart';
import 'package:scimovement/screens/journal/widgets/pain_slider.dart';
import 'package:scimovement/screens/journal/widgets/pressure_release_exercise_select.dart';
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

  FormGroup buildForm() => fb.group({
        if (entry is PainLevelEntry || type == JournalType.pain)
          ...buildPainLevelForm(),
        if (entry is PressureReleaseEntry ||
            type == JournalType.pressureRelease)
          ...buildPressureReleaseForm(),
        'comment': FormControl<String>(
          value: entry?.comment ?? '',
        ),
      });

  buildPainLevelForm() {
    PainLevelEntry? painLevelEntry = entry as PainLevelEntry?;
    return {
      'bodyPartType': FormControl<BodyPartType>(
        value: painLevelEntry?.bodyPart.type,
        validators: [Validators.required],
      ),
      'side': FormControl<Side>(
        value: painLevelEntry?.bodyPart.side ?? Side.right,
        validators: [Validators.required],
      ),
      'painLevel': FormControl<int>(
        value: painLevelEntry?.painLevel ?? 0,
        validators: [
          Validators.required,
          Validators.min(0),
          Validators.max(10)
        ],
      ),
    };
  }

  buildPressureReleaseForm() {
    PressureReleaseEntry? pressureReleaseEntry = entry as PressureReleaseEntry?;

    return {
      'exercises': FormControl<List<PressureReleaseExercise>>(
        value: pressureReleaseEntry?.exercises ?? [],
      ),
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // BodyPart? initialBodyPart = entry != null ? entry!.bodyPart : bodyPart;
    return Scaffold(
      appBar: AppTheme.appBar('test'),
      body: ReactiveFormBuilder(
        form: buildForm,
        builder: (context, form, _) {
          return ListView(
            padding: AppTheme.screenPadding,
            children: [
              if (entry is PainLevelEntry || type == JournalType.pain)
                PainLevelForm(form: form, entry: entry as PainLevelEntry?),
              if (entry is PressureReleaseEntry ||
                  type == JournalType.pressureRelease)
                PressureReleaseForm(form: form),
              StyledTextField(
                formControlName: 'comment',
                placeholder:
                    AppLocalizations.of(context)!.painCommentPlaceholder,
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
                              .createJournalEntry(
                                  entry?.type ?? type!, form.value);
                        } else {
                          await ref
                              .read(updateJournalProvider.notifier)
                              .updateJournalEntry(entry!, form.value);
                        }
                        form.reset();
                        while (context.canPop()) {
                          context.pop();
                        }
                      },
                      title: entry != null
                          ? AppLocalizations.of(context)!.update
                          : AppLocalizations.of(context)!.save,
                    )),
              ),
            ],
          );
        },
      ),
    );
  }
}

class PainLevelForm extends StatelessWidget {
  final PainLevelEntry? entry;
  final FormGroup form;

  const PainLevelForm({
    Key? key,
    this.entry,
    required this.form,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (entry == null) BodyPartSelect(form: form),
        if (entry == null) AppTheme.spacer2x,
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
      ],
    );
  }
}

class PressureReleaseForm extends StatelessWidget {
  final FormGroup form;

  const PressureReleaseForm({
    super.key,
    required this.form,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PressureReleaseExerciseSelect(form: form),
      ],
    );
  }
}
