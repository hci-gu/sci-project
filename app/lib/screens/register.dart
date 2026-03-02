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
        validators: [Validators.required, Validators.minLength(8)],
      ),
      'verifyPassword': FormControl<String>(value: ''),
      'weight': FormControl<int>(value: null, validators: []),
      'injuryLevel': FormControl<int>(value: null, validators: []),
      'gender': FormControl<Gender>(value: null, validators: []),
      'condition': FormControl<Condition>(value: null, validators: []),
    },
    validators: [Validators.mustMatch('password', 'verifyPassword')],
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
    BuildContext context,
    WidgetRef ref,
    ValueNotifier<bool> loading,
  ) {
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
            ConditionDropDown(form: form),
            AppTheme.spacer,
            FormDropdown(
              form: form,
              formKey: 'gender',
              title: AppLocalizations.of(context)!.gender,
              hint:
                  '${AppLocalizations.of(context)!.select} ${AppLocalizations.of(context)!.gender.toLowerCase()}',
              items:
                  Gender.values
                      .map(
                        (gender) => DropdownMenuItem(
                          value: gender,
                          child: Text(gender.name),
                        ),
                      )
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
      },
    );
  }

  Widget _header(BuildContext context) {
    return Column(
      children: [
        Text(
          AppLocalizations.of(context)!.appName,
          style: AppTheme.headLine1.copyWith(height: 0.5),
        ),
        Text(
          AppLocalizations.of(context)!.introductionScreenHeader,
          style: AppTheme.headLine3Light.copyWith(
            color: AppTheme.colors.primary,
          ),
        ),
      ],
    );
  }

  Widget _registerButton(
    BuildContext context,
    WidgetRef ref,
    ValueNotifier<bool> loading,
  ) {
    return ReactiveFormConsumer(
      builder:
          ((context, form, child) => Button(
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
                      String message =
                          AppLocalizations.of(context)!.genericError;
                      // check if error is Dio connection timeout
                      if (e is DioException) {
                        if (e.type == DioExceptionType.connectionTimeout) {
                          message =
                              AppLocalizations.of(context)!.connectionTimeout;
                        }
                        if (e.type == DioExceptionType.connectionError) {
                          message =
                              AppLocalizations.of(context)!.connectionError;
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

  Future<bool> _confirm(BuildContext context) async {
    int step = 0;
    bool consentChecked = false;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext statefulContext, StateSetter setState) {
            final isInfoStep = step == 0;
            final l10n = AppLocalizations.of(statefulContext)!;

            return AlertDialog(
              title: Text(l10n.registerDataTitle, style: AppTheme.headLine3),
              titlePadding: EdgeInsets.symmetric(
                horizontal: AppTheme.basePadding * 2,
                vertical: AppTheme.basePadding,
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: AppTheme.basePadding * 2,
              ),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(8.0)),
              ),
              content:
                  isInfoStep
                      ? _informationStepBody(statefulContext)
                      : _consentStepBody(statefulContext, consentChecked, (
                        bool? value,
                      ) {
                        setState(() {
                          consentChecked = value ?? false;
                        });
                      }),
              actionsPadding: EdgeInsets.all(AppTheme.basePadding * 2),
              actions: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Expanded(
                      child: Button(
                        onPressed: () {
                          if (isInfoStep) {
                            Navigator.of(dialogContext).pop(false);
                            return;
                          }
                          setState(() {
                            step = 0;
                          });
                        },
                        secondary: true,
                        rounded: true,
                        size: ButtonSize.small,
                        title: isInfoStep ? l10n.cancel : l10n.back,
                      ),
                    ),
                    SizedBox(width: AppTheme.basePadding * 4),
                    Expanded(
                      child: Button(
                        onPressed: () {
                          if (isInfoStep) {
                            setState(() {
                              step = 1;
                            });
                            return;
                          }
                          Navigator.of(dialogContext).pop(true);
                        },
                        rounded: true,
                        size: ButtonSize.small,
                        disabled: !isInfoStep && !consentChecked,
                        title: isInfoStep ? l10n.next : l10n.createAccount,
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );

    return result ?? false;
  }

  Widget _informationStepBody(BuildContext context) {
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.55,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _researchInformationText(context),
            AppTheme.spacer,
            Text(
              AppLocalizations.of(context)!.registerDataDeletion,
              style: AppTheme.paragraphMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _consentStepBody(
    BuildContext context,
    bool consentChecked,
    ValueChanged<bool?> onConsentChanged,
  ) {
    return SizedBox(
      width: double.maxFinite,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.registerProceed,
            style: AppTheme.paragraphMedium,
          ),
          AppTheme.spacer,
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(value: consentChecked, onChanged: onConsentChanged),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    AppLocalizations.of(context)!.registerConsentCheckbox,
                    style: AppTheme.paragraphMedium,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _researchInformationText(BuildContext context) {
    final text = AppLocalizations.of(context)!.registerResearchInformation;
    final paragraphs = text.split('\n\n');
    final baseStyle = AppTheme.paragraphMedium;
    final headerStyle = AppTheme.paragraphMedium.copyWith(
      fontWeight: FontWeight.w700,
    );
    final spans = <InlineSpan>[];

    for (int i = 0; i < paragraphs.length; i++) {
      final paragraph = paragraphs[i];
      if (paragraph.isEmpty) {
        continue;
      }

      if (i == 0) {
        spans.add(TextSpan(text: paragraph, style: headerStyle));
      } else {
        final colonIndex = paragraph.indexOf(':');
        final hasHeader = colonIndex > 0 && colonIndex < 60;

        if (hasHeader) {
          spans.add(
            TextSpan(
              text: paragraph.substring(0, colonIndex + 1),
              style: headerStyle,
            ),
          );
          spans.add(TextSpan(text: paragraph.substring(colonIndex + 1)));
        } else {
          spans.add(TextSpan(text: paragraph));
        }
      }

      if (i < paragraphs.length - 1) {
        spans.add(const TextSpan(text: '\n\n'));
      }
    }

    return RichText(text: TextSpan(style: baseStyle, children: spans));
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
