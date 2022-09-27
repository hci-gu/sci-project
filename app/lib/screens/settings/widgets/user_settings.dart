import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:scimovement/api.dart';
import 'package:scimovement/models/auth.dart';
import 'package:scimovement/screens/settings/settings.dart';
import 'package:scimovement/screens/settings/widgets/form_dropdown.dart';
import 'package:scimovement/theme/theme.dart';
import 'package:scimovement/widgets/button.dart';
import 'package:scimovement/widgets/snackbar_message.dart';
import 'package:scimovement/widgets/text_field.dart';

class UserSettings extends HookWidget {
  final User user;

  const UserSettings({Key? key, required this.user}) : super(key: key);

  FormGroup buildForm() => fb.group(
        {
          'email': FormControl<String>(
            value: 'test@email.com',
            validators: [
              Validators.email,
            ],
          ),
          'weight': FormControl<int>(
            value: user.weight != null ? user.weight!.toInt() : 0,
            validators: [
              Validators.required,
            ],
          ),
          'injuryLevel': FormControl<int>(
            value: user.injuryLevel ?? 0,
            validators: [
              Validators.number,
            ],
          ),
          'gender': FormControl<Gender>(
            value: user.gender,
            validators: [],
          ),
          'condition': FormControl<Condition>(
            value: user.condition,
            validators: [],
          ),
        },
      );

  @override
  Widget build(BuildContext context) {
    ValueNotifier<bool> editing = useState(false);

    return ReactiveFormBuilder(
      form: buildForm,
      builder: (context, form, _) {
        return Column(
          children: [
            StyledTextField(
              formControlName: 'email',
              placeholder: 'Email',
              keyboardType: TextInputType.emailAddress,
              canEdit: editing.value,
              disabled: !editing.value,
            ),
            AppTheme.spacer,
            ConditionDropDown(
              form: form,
              readOnly: !editing.value,
            ),
            AppTheme.spacer,
            FormDropdown(
              form: form,
              formKey: 'gender',
              title: 'Kön',
              readOnly: !editing.value,
              items: Gender.values
                  .map((gender) => DropdownMenuItem(
                        value: gender,
                        child: Text(gender.name),
                      ))
                  .toList(),
            ),
            AppTheme.spacer,
            StyledTextField(
              formControlName: 'weight',
              placeholder: 'Vikt',
              keyboardType: TextInputType.number,
              canEdit: editing.value,
              disabled: !editing.value,
            ),
            AppTheme.spacer,
            editing.value
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Button(
                        title: 'Avbryt',
                        width: 120,
                        secondary: true,
                        onPressed: () => editing.value = !editing.value,
                      ),
                      AppTheme.spacer2x,
                      const SubmitButton(),
                    ],
                  )
                : Button(
                    title: 'Editera profil',
                    width: 200,
                    secondary: true,
                    onPressed: () => editing.value = !editing.value,
                  ),
          ],
        );
      },
    );
  }
}

class ConditionDropDown extends StatelessWidget {
  final FormGroup form;
  final bool readOnly;

  const ConditionDropDown({
    Key? key,
    required this.form,
    this.readOnly = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ReactiveFormConsumer(
      builder: ((context, formGroup, child) => Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              Flexible(
                child: FormDropdown(
                  readOnly: readOnly,
                  form: form,
                  formKey: 'condition',
                  title: 'Tillstånd',
                  items: Condition.values
                      .map((condition) => DropdownMenuItem(
                            value: condition,
                            child: Text(condition.name),
                          ))
                      .toList(),
                ),
              ),
              if (form.value['condition'] == Condition.tetraplegic)
                const SizedBox(width: 16),
              if (form.value['condition'] == Condition.tetraplegic)
                Flexible(
                  child: FormDropdown(
                    readOnly: readOnly,
                    form: form,
                    formKey: 'injuryLevel',
                    title: 'Skadenivå',
                    items: [5, 6, 7, 8, 9]
                        .map((value) => DropdownMenuItem(
                              value: value,
                              child: Text(value.toString()),
                            ))
                        .toList(),
                  ),
                )
            ],
          )),
    );
  }
}

class SubmitButton extends ConsumerWidget {
  const SubmitButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ReactiveFormConsumer(
      builder: ((context, form, child) => Button(
            title: 'Spara',
            width: 130,
            disabled: form.pristine || !form.valid,
            onPressed: () async {
              FocusManager.instance.primaryFocus?.unfocus();
              try {
                await ref.read(userProvider.notifier).update({
                  'weight': form.value['weight'],
                  'injuryLevel': form.value['injuryLevel'],
                  'gender': (form.value['gender'] as Gender).name,
                  'condition': (form.value['condition'] as Condition).name,
                });
              } catch (e) {
                return;
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackbarMessage(
                  context: context,
                  message: 'Uppdaterad',
                ),
              );
            },
          )),
    );
  }
}
