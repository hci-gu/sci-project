import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:scimovement/api/classes.dart';
import 'package:scimovement/models/auth.dart';
import 'package:scimovement/screens/settings/widgets/form_dropdown.dart';
import 'package:scimovement/screens/settings/widgets/user_settings.dart';
import 'package:scimovement/theme/theme.dart';
import 'package:scimovement/widgets/button.dart';
import 'package:scimovement/widgets/confirm_dialog.dart';
import 'package:scimovement/widgets/snackbar_message.dart';
import 'package:scimovement/widgets/text_field.dart';
import 'package:scimovement/gen_l10n/app_localizations.dart';

class RegisterScreen extends HookConsumerWidget {
  const RegisterScreen({super.key});

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
    ValueNotifier<bool> loading = useState(false);

    return Scaffold(
      appBar: AppTheme.appBar(AppLocalizations.of(context)!.register),
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
              StyledTextField(
                formControlName: 'verifyPassword',
                placeholder: AppLocalizations.of(context)!.verifyPassword,
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
                title: AppLocalizations.of(context)!.gender,
                hint:
                    '${AppLocalizations.of(context)!.select} ${AppLocalizations.of(context)!.gender.toLowerCase()}',
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
                placeholder: AppLocalizations.of(context)!.weight,
                keyboardType: TextInputType.number,
              ),
              AppTheme.separator,
              _registerButton(context, ref, loading),
            ],
          );
        });
  }

  Widget _header(BuildContext context) {
    return Column(
      children: [
        Text(AppLocalizations.of(context)!.appName,
            style: AppTheme.headLine1.copyWith(height: 0.5)),
        Text(
          AppLocalizations.of(context)!.introductionScreenHeader,
          style:
              AppTheme.headLine3Light.copyWith(color: AppTheme.colors.primary),
        ),
      ],
    );
  }

  Widget _registerButton(
      BuildContext context, WidgetRef ref, ValueNotifier<bool> loading) {
    return ReactiveFormConsumer(
      builder: ((context, form, child) => Button(
            title: AppLocalizations.of(context)!.createAccount,
            width: 130,
            disabled: form.pristine || !form.valid,
            loading: loading.value,
            onPressed: () async {
              bool proceed = await _confirm(context);
              if (!proceed) return;
              FocusManager.instance.primaryFocus?.unfocus();
              String email = form.value['email'] as String;
              String password = form.value['password'] as String;
              loading.value = true;
              await ref
                  .read(userProvider.notifier)
                  .register(email, password, _formToBody(form.rawValue))
                  .catchError((e) {
                if (context.mounted) {
                  String message = AppLocalizations.of(context)!.genericError;
                  // check if error is Dio connection timeout
                  if (e is DioException) {
                    if (e.type == DioExceptionType.connectionTimeout) {
                      message = AppLocalizations.of(context)!.connectionTimeout;
                    }
                    if (e.type == DioExceptionType.connectionError) {
                      message = AppLocalizations.of(context)!.connectionError;
                    }
                  }
                  loading.value = false;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackbarMessage(
                      context: context,
                      message: message,
                      type: SnackbarType.error,
                    ),
                  );
                }
              });
              loading.value = false;
            },
          )),
    );
  }

  Future _confirm(BuildContext context) {
    return confirmDialog(
      context,
      title: AppLocalizations.of(context)!.registerDataTitle,
      message: '',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            AppLocalizations.of(context)!.registerDataDescription,
            style: AppTheme.paragraphMedium,
          ),
          AppTheme.spacer,
          Text(
            AppLocalizations.of(context)!.registerDataDeletion,
            style: AppTheme.paragraphMedium,
          ),
          AppTheme.spacer,
          Text(
            AppLocalizations.of(context)!.registerProceed,
            style: AppTheme.labelMedium,
          ),
        ],
      ),
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
