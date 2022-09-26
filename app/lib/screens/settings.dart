import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:scimovement/api.dart';
import 'package:scimovement/models/auth.dart';
import 'package:scimovement/theme/theme.dart';
import 'package:scimovement/widgets/button.dart';
import 'package:scimovement/widgets/snackbar_message.dart';
import 'package:scimovement/widgets/text_field.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    User? user = ref.watch(userProvider);

    if (user != null) {
      return UserSettings(user);
    }
    return const Center(child: CircularProgressIndicator());
  }
}

class UserSettings extends StatelessWidget {
  final User user;

  const UserSettings(
    this.user, {
    Key? key,
  }) : super(key: key);

  FormGroup buildForm() => fb.group(
        {
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

  Widget get spacer => const SizedBox(height: 16);

  @override
  Widget build(BuildContext context) {
    return ReactiveFormBuilder(
      form: buildForm,
      builder: (context, form, _) {
        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          children: [
            const Text(
              'Profil',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),
            spacer,
            ReactiveFormConsumer(
                builder: ((context, formGroup, child) => Row(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Flexible(
                          child: FormDropdown(
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
                    ))),
            spacer,
            FormDropdown(
              form: form,
              formKey: 'gender',
              title: 'Kön',
              items: Gender.values
                  .map((gender) => DropdownMenuItem(
                        value: gender,
                        child: Text(gender.name),
                      ))
                  .toList(),
            ),
            spacer,
            const StyledTextField(
              formControlName: 'weight',
              placeholder: 'Vikt',
              keyboardType: TextInputType.number,
            ),
            spacer,
            const SubmitButton(),
            spacer,
            _separator(),
            spacer,
            const Text(
              'App inställningar',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            spacer,
            _separator(),
            spacer,
            const LogoutButton(),
            spacer,
            _separator(),
            spacer,
            const Text(
              'AnvändarID:',
              textAlign: TextAlign.center,
            ),
            Text(
              user.id,
              textAlign: TextAlign.center,
            ),
          ],
        );
      },
    );
  }

  Widget _separator() {
    return Container(
      color: const Color.fromRGBO(0, 0, 0, 0.1),
      width: 5000,
      height: 1,
    );
  }
}

class SubmitButton extends ConsumerWidget {
  const SubmitButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ReactiveFormConsumer(
      builder: ((context, form, child) => Button(
            title: 'Save profile information',
            width: 240,
            disabled: form.pristine || !form.valid,
            secondary: true,
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

class LogoutButton extends ConsumerWidget {
  const LogoutButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Button(
      title: 'Logga ut',
      width: 220,
      secondary: true,
      onPressed: () => ref.read(userProvider.notifier).logout(),
    );
  }
}

class FormDropdown extends StatelessWidget {
  final String formKey;
  final String title;
  final FormGroup form;
  final List<DropdownMenuItem> items;

  const FormDropdown({
    Key? key,
    required this.formKey,
    required this.title,
    required this.form,
    this.items = const [],
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ReactiveDropdownField<dynamic>(
      formControlName: formKey,
      hint: const Text('Välj typ'),
      icon: const Icon(Icons.keyboard_arrow_down),
      iconSize: 32,
      isDense: false,
      selectedItemBuilder: (_) {
        return items
            .map(
              (i) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTheme.labelTiny,
                  ),
                  i.child,
                ],
              ),
            )
            .toList();
      },
      decoration: InputDecoration(
        isDense: true,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4.0),
          borderSide: const BorderSide(
            color: Color.fromRGBO(0, 0, 0, 0.1),
            width: 1,
          ),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4.0),
          borderSide: const BorderSide(
            color: Color.fromRGBO(0, 255, 0, 0.1),
            width: 1,
          ),
        ),
      ),
      items: items,
    );
  }
}
