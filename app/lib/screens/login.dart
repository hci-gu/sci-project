import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:scimovement/models/auth.dart';
import 'package:scimovement/theme/theme.dart';
import 'package:scimovement/widgets/button.dart';
import 'package:scimovement/widgets/text_field.dart';
import 'package:url_launcher/url_launcher.dart';

class LoginScreen extends HookConsumerWidget {
  const LoginScreen({Key? key}) : super(key: key);

  FormGroup buildForm() => fb.group({
        'userId': FormControl<String>(
          value: '',
          validators: [
            Validators.required,
          ],
        ),
      });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final _userIdController = useTextEditingController();

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
                formControlName: 'userId',
                placeholder: 'UserId',
                keyboardType: TextInputType.emailAddress,
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
              try {
                ref
                    .read(userProvider.notifier)
                    .login(form.value['userId'] as String);
              } catch (e) {
                return;
              }
            },
          )),
    );
  }

  Future<void> _launchFitbitGallery() async {
    if (!await launchUrl(
      Uri.https(
        'gallery.fitbit.com',
        'details/1c0a1dfd-e31d-4ed7-bb74-b653337a9e8d/openapp',
      ),
      mode: LaunchMode.externalApplication,
    )) {
      throw 'Could not launch';
    }
  }
}
