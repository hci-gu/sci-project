import 'dart:html';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:scimovement/api/classes.dart';
import 'package:scimovement/models/journal.dart';
import 'package:scimovement/screens/journal/widgets/pain_slider.dart';
import 'package:scimovement/screens/settings/widgets/form_dropdown.dart';
import 'package:scimovement/theme/theme.dart';
import 'package:scimovement/widgets/button.dart';
import 'package:scimovement/widgets/text_field.dart';

class CreateJournalEntryScreen extends ConsumerWidget {
  final BodyPart? bodyPart;
  final Arm? arm;

  const CreateJournalEntryScreen({
    Key? key,
    this.bodyPart,
    this.arm,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppTheme.appBar('title'),
      body: ListView(
        padding: AppTheme.screenPadding,
        children: [
          CreateJournal(
            initialBodyPart: bodyPart,
            initialArm: arm,
          ),
        ],
      ),
    );
  }
}

class CreateJournal extends ConsumerWidget {
  final BodyPart? initialBodyPart;
  final Arm? initialArm;

  const CreateJournal({
    Key? key,
    this.initialBodyPart,
    this.initialArm,
  }) : super(key: key);

  FormGroup buildForm() => fb.group({
        'bodyPart': FormControl<BodyPart>(value: initialBodyPart),
        'arm': FormControl<Arm>(value: initialArm ?? Arm.right),
        'painLevel': FormControl<int>(
          value: 0,
          validators: [
            Validators.required,
            Validators.min(0),
            Validators.max(10)
          ],
        ),
        'comment': FormControl<String>(
          value: '',
        ),
      });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ReactiveFormBuilder(
      form: buildForm,
      builder: (context, form, _) {
        return Column(
          children: [
            BodyPartSelect(form: form),
            AppTheme.spacer2x,
            const StyledTextField(
              formControlName: 'comment',
              placeholder: 'comment',
            ),
            AppTheme.spacer2x,
            PainSlider(formKey: 'painLevel'),
            Button(
              width: 160,
              onPressed: () async {
                await ref
                    .read(updateJournalProvider.notifier)
                    .createJournalEntry(form.value);
                form.reset();
                GoRouter.of(context).pop();
              },
              title: 'Create entry',
            ),
          ],
        );
      },
    );
  }
}

class BodyPartSelect extends StatelessWidget {
  final FormGroup form;

  const BodyPartSelect({Key? key, required this.form}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ReactiveFormConsumer(
      builder: ((context, formGroup, child) => Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              Flexible(
                flex: 2,
                child: FormDropdown(
                  formKey: 'bodyPart',
                  title: 'Kroppsdel',
                  form: form,
                  hint: 'Välj kroppsdel',
                  items: BodyPart.values
                      .map((bodyPart) => DropdownMenuItem(
                            value: bodyPart,
                            child: Text(bodyPart.displayString()),
                          ))
                      .toList(),
                ),
              ),
              if (form.value['bodyPart'] != null &&
                  form.value['bodyPart'] != BodyPart.neck)
                AppTheme.spacer2x,
              if (form.value['bodyPart'] != null &&
                  form.value['bodyPart'] != BodyPart.neck)
                Flexible(
                  flex: 1,
                  child: FormDropdown(
                    formKey: 'arm',
                    title: 'Arm',
                    form: form,
                    hint: 'Välj arm',
                    items: Arm.values
                        .map((arm) => DropdownMenuItem(
                              value: arm,
                              child: Text(arm.displayString()),
                            ))
                        .toList(),
                  ),
                ),
            ],
          )),
    );
  }
}
