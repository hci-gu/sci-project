import 'package:flutter/material.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:scimovement/api.dart';
import 'package:scimovement/models/auth.dart';
import 'package:scimovement/widgets/button.dart';
import 'package:scimovement/widgets/snackbar_message.dart';
import 'package:scimovement/widgets/text_field.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    AuthModel auth = Provider.of<AuthModel>(context);

    if (auth.user != null) {
      return UserSettings(auth.user!, auth: auth);
    }
    return const Center(child: CircularProgressIndicator());
  }
}

class UserSettings extends StatelessWidget {
  final User user;
  final AuthModel auth;

  const UserSettings(
    this.user, {
    Key? key,
    required this.auth,
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
              'Profile',
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
                            title: 'Condition',
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
                              title: 'Injury level',
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
              title: 'Gender',
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
            ReactiveFormConsumer(
              builder: ((context, formGroup, child) =>
                  _submitButton(context, form)),
            ),
            spacer,
            _separator(),
            spacer,
            const Text(
              'App settings',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            spacer,
            _separator(),
            spacer,
            _logoutButton(context),
            spacer,
            _separator(),
            spacer,
            const Text(
              'AnvändarID:',
              textAlign: TextAlign.center,
            ),
            Text(
              auth.user?.id ?? '',
              textAlign: TextAlign.center,
            ),
          ],
        );
      },
    );
  }

  Widget _submitButton(BuildContext context, FormGroup form) {
    return Button(
      loading: auth.loading,
      title: 'Save profile information',
      width: 240,
      disabled: form.pristine || !form.valid,
      secondary: true,
      onPressed: () async {
        FocusManager.instance.primaryFocus?.unfocus();
        try {
          await auth.updateUser({
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
    );
  }

  Widget _logoutButton(BuildContext context) {
    return Button(
      title: 'Logga ut',
      width: 220,
      secondary: true,
      onPressed: () async {
        FocusManager.instance.primaryFocus?.unfocus();
        await auth.logout();
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
      selectedItemBuilder: (_) {
        return items
            .map((i) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontSize: 11),
                    ),
                    // const SizedBox(height: 8),
                    i.child,
                  ],
                ))
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
