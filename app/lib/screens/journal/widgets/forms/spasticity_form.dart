import 'package:flutter/material.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:scimovement/api/classes/journal/spasticity.dart';
import 'package:scimovement/screens/journal/widgets/number_slider.dart';
import 'package:scimovement/theme/theme.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SpasticityForm extends StatelessWidget {
  final FormGroup form;
  final SpasticityEntry? entry;

  const SpasticityForm({
    super.key,
    required this.form,
    this.entry,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.spasticityLevel,
          style: AppTheme.labelLarge,
        ),
        Text(
          AppLocalizations.of(context)!.spasticityLevelDescription,
          style: AppTheme.paragraphMedium,
        ),
        AppTheme.spacer2x,
        NumberSlider(formKey: 'level'),
        AppTheme.spacer2x,
      ],
    );
  }

  static buildForm(SpasticityEntry? entry) {
    return {
      'level': FormControl<int>(
        value: entry?.level ?? 0,
        validators: [
          Validators.required,
          Validators.min(0),
          Validators.max(10)
        ],
      ),
    };
  }
}
