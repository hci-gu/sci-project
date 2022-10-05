import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:scimovement/models/auth.dart';
import 'package:scimovement/theme/theme.dart';
import 'package:scimovement/widgets/button.dart';
import 'package:scimovement/widgets/snackbar_message.dart';
import 'package:scimovement/widgets/text_field.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({Key? key}) : super(key: key);

  FormGroup buildForm() => fb.group({
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
      });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppTheme.appBar('Logga in'),
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
              _loginButton(ref),
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

  Widget _loginButton(WidgetRef ref) {
    return ReactiveFormConsumer(
      builder: ((context, form, child) => Button(
            title: 'Logga in',
            width: 130,
            disabled: form.pristine || !form.valid,
            onPressed: () async {
              FocusManager.instance.primaryFocus?.unfocus();
              String email = form.value['email'] as String;
              String password = form.value['password'] as String;
              ref
                  .read(userProvider.notifier)
                  .login(email, password)
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
}
