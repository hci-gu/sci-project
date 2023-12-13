import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:scimovement/models/auth.dart';
import 'package:scimovement/theme/theme.dart';
import 'package:scimovement/widgets/button.dart';
import 'package:scimovement/widgets/snackbar_message.dart';
import 'package:scimovement/widgets/text_field.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class LoginScreen extends HookConsumerWidget {
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
    ValueNotifier<bool> loading = useState(false);

    return Scaffold(
      appBar: AppTheme.appBar(AppLocalizations.of(context)!.login),
      body: Padding(
        padding: AppTheme.screenPadding,
        child: ListView(
          children: [
            const SizedBox(height: 64),
            _header(context),
            AppTheme.spacer2x,
            _form(context, ref, loading),
          ],
        ),
      ),
    );
  }

  Widget _form(
      BuildContext context, WidgetRef ref, ValueNotifier<bool> loading) {
    return ReactiveFormBuilder(
        form: buildForm,
        builder: (context, form, _) {
          return Column(
            children: [
              StyledTextField(
                formControlName: 'email',
                placeholder: AppLocalizations.of(context)!.email,
                keyboardType: TextInputType.emailAddress,
              ),
              AppTheme.spacer2x,
              StyledTextField(
                formControlName: 'password',
                placeholder: AppLocalizations.of(context)!.password,
                keyboardType: TextInputType.visiblePassword,
                obscureText: true,
              ),
              AppTheme.spacer2x,
              _loginButton(context, ref, loading),
            ],
          );
        });
  }

  Widget _header(BuildContext context) {
    return Column(
      children: [
        Text('RullaPå', style: AppTheme.headLine1.copyWith(height: 0.5)),
        Text(
          AppLocalizations.of(context)!.introductionScreenHeader,
          style: AppTheme.headLine3Light.copyWith(
            color: AppTheme.colors.primary,
          ),
        ),
      ],
    );
  }

  Widget _loginButton(
      BuildContext context, WidgetRef ref, ValueNotifier<bool> loading) {
    return ReactiveFormConsumer(
      builder: ((context, form, child) => Button(
            title: AppLocalizations.of(context)!.login,
            width: 130,
            disabled: form.pristine || !form.valid,
            loading: loading.value,
            onPressed: () async {
              FocusManager.instance.primaryFocus?.unfocus();
              String email = form.value['email'] as String;
              String password = form.value['password'] as String;
              loading.value = true;
              await ref
                  .read(userProvider.notifier)
                  .login(email, password)
                  .catchError((e) {
                String message = AppLocalizations.of(context)!.genericError;
                // check if error is Dio connection timeout
                if (e is DioError) {
                  if (e.type == DioErrorType.connectionTimeout) {
                    message = AppLocalizations.of(context)!.connectionTimeout;
                  }
                  if (e.type == DioErrorType.connectionError) {
                    message = AppLocalizations.of(context)!.connectionError;
                  }
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackbarMessage(
                    context: context,
                    message: message,
                    type: SnackbarType.error,
                  ),
                );
                loading.value = false;
              });
              loading.value = false;
            },
          )),
    );
  }
}
