import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:scimovement/api.dart';
import 'package:scimovement/models/auth.dart';
import 'package:scimovement/screens/settings/widgets/form_dropdown.dart';
import 'package:scimovement/screens/settings/widgets/user_settings.dart';
import 'package:scimovement/theme/theme.dart';
import 'package:scimovement/widgets/button.dart';
import 'package:scimovement/widgets/snackbar_message.dart';
import 'package:scimovement/widgets/text_field.dart';

class RegisterScreen extends ConsumerWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  FormGroup buildForm() => FormGroup(
        {
          'email': FormControl<String>(
            value: '',
            validators: [Validators.required, Validators.email],
          ),
          'password': FormControl<String>(
            value: '',
            validators: [
              Validators.required,
              Validators.minLength(8),
            ],
          ),
          'verifyPassword': FormControl<String>(value: ''),
          'weight': FormControl<int>(
            value: null,
            validators: [],
          ),
          'injuryLevel': FormControl<int>(
            value: null,
            validators: [],
          ),
          'gender': FormControl<Gender>(
            value: null,
            validators: [],
          ),
          'condition': FormControl<Condition>(
            value: null,
            validators: [],
          ),
        },
        validators: [
          Validators.mustMatch('password', 'verifyPassword'),
        ],
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppTheme.appBar('Registrera'),
      body: Padding(
        padding: AppTheme.screenPadding,
        child: ListView(
          children: [
            const SizedBox(height: 100),
            _header(),
            const SizedBox(height: 16.0),
            _form(ref),
          ],
        ),
      ),
    );
  }

  Widget _form(WidgetRef ref) {
    return ReactiveFormBuilder(
        form: buildForm,
        builder: (context, form, _) {
          return Column(
            children: [
              const StyledTextField(
                formControlName: 'email',
                placeholder: 'Email',
                keyboardType: TextInputType.emailAddress,
              ),
              AppTheme.spacer2x,
              const StyledTextField(
                formControlName: 'password',
                placeholder: 'Lösenord',
                keyboardType: TextInputType.visiblePassword,
                obscureText: true,
              ),
              AppTheme.spacer2x,
              const StyledTextField(
                formControlName: 'verifyPassword',
                placeholder: 'Verifiera lösenord',
                keyboardType: TextInputType.visiblePassword,
                obscureText: true,
              ),
              AppTheme.separator,
              ConditionDropDown(
                form: form,
              ),
              AppTheme.spacer,
              FormDropdown(
                form: form,
                formKey: 'gender',
                title: 'Kön',
                hint: 'Välj kön',
                items: Gender.values
                    .map((gender) => DropdownMenuItem(
                          value: gender,
                          child: Text(gender.name),
                        ))
                    .toList(),
              ),
              AppTheme.spacer,
              const StyledTextField(
                formControlName: 'weight',
                placeholder: 'Vikt',
                keyboardType: TextInputType.number,
              ),
              AppTheme.separator,
              _registerButton(ref),
            ],
          );
        });
  }

  Widget _header() {
    return Column(
      children: [
        Text('RullaPå', style: AppTheme.headLine1.copyWith(height: 0.5)),
        Text(
          'spåra din rörelse',
          style:
              AppTheme.headLine3Light.copyWith(color: AppTheme.colors.primary),
        ),
      ],
    );
  }

  Widget _registerButton(WidgetRef ref) {
    return ReactiveFormConsumer(
      builder: ((context, form, child) => Button(
            title: 'Skapa konto',
            width: 130,
            disabled: form.pristine || !form.valid,
            onPressed: () async {
              FocusManager.instance.primaryFocus?.unfocus();
              String email = form.value['email'] as String;
              String password = form.value['password'] as String;
              ref
                  .read(userProvider.notifier)
                  .register(email, password, _formToBody(form.rawValue))
                  .catchError((_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackbarMessage(
                    context: context,
                    message: 'Något gick fel',
                    type: SnackbarType.error,
                  ),
                );
              });
            },
          )),
    );
  }

  Map<dynamic, dynamic> _formToBody(Map<String, Object?> formValues) {
    Map<dynamic, dynamic> body = {};
    Condition? condition = formValues['condition'] as Condition?;
    body['condition'] = condition?.name;
    body['gender'] = (formValues['gender'] as Gender?)?.name;
    body['weight'] = formValues['weight'];
    if (condition == Condition.tetraplegic) {
      body['injuryLevel'] = formValues['injuryLevel'];
    }

    return body;
  }
}
