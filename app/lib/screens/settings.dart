import 'package:flutter/material.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:scimovement/api.dart';
import 'package:scimovement/models/auth.dart';
import 'package:scimovement/widgets/button.dart';
import 'package:scimovement/widgets/snackbar_message.dart';
import 'package:scimovement/widgets/text_field.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatelessWidget {
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

  FormGroup buildForm() => fb.group({
        'weight': FormControl<int>(
          value: user.weight != null ? user.weight!.toInt() : 0,
          validators: [],
        ),
        'injuryLevel': FormControl<int>(
          value: user.injuryLevel ?? 0,
          validators: [],
        ),
        'gender': FormControl<Gender>(
          value: user.gender,
          validators: [],
        ),
        'condition': FormControl<Condition>(
          value: user.condition,
          validators: [],
        ),
      });

  @override
  Widget build(BuildContext context) {
    return ReactiveFormBuilder(
      form: buildForm,
      builder: (context, form, _) {
        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          children: [
            ReactiveDropdownField(
              formControlName: 'condition',
              hint: const Text('Select condition'),
              items: Condition.values
                  .map((condition) => DropdownMenuItem(
                        value: condition,
                        child: Text(condition.name),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),
            ReactiveDropdownField(
              formControlName: 'gender',
              hint: const Text('Select gender'),
              items: Gender.values
                  .map((gender) => DropdownMenuItem(
                        value: gender,
                        child: Text(gender.name),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),
            const StyledTextField(
              formControlName: 'weight',
              placeholder: 'Weight',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            const StyledTextField(
              formControlName: 'injuryLevel',
              placeholder: 'Injury level',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            _submitButton(context, form),
            const SizedBox(height: 16),
            _logoutButton(context),
          ],
        );
      },
    );
  }

  Widget _submitButton(BuildContext context, FormGroup form) {
    return Button(
      loading: auth.loading,
      title: 'Update',
      width: 220,
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
            message: 'Updated',
          ),
        );
      },
    );
  }

  Widget _logoutButton(BuildContext context) {
    return Button(
      title: 'Logout',
      width: 220,
      secondary: true,
      onPressed: () async {
        FocusManager.instance.primaryFocus?.unfocus();
        await auth.logout();
      },
    );
  }
}
