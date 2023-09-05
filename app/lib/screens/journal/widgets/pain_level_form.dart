import 'package:flutter/material.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:scimovement/api/classes.dart';
import 'package:scimovement/screens/journal/widgets/body_part_select.dart';
import 'package:scimovement/screens/journal/widgets/pain_slider.dart';
import 'package:scimovement/theme/theme.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class PainLevelForm extends StatelessWidget {
  final PainLevelEntry? entry;
  final FormGroup form;

  const PainLevelForm({
    Key? key,
    this.entry,
    required this.form,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (entry == null) BodyPartSelect(form: form),
        if (entry == null) AppTheme.spacer2x,
        Text(
          AppLocalizations.of(context)!.painLevel,
          style: AppTheme.labelLarge,
        ),
        Text(
          AppLocalizations.of(context)!.painLevelHelper,
          style: AppTheme.paragraphMedium,
        ),
        AppTheme.spacer2x,
        PainSlider(formKey: 'painLevel'),
        AppTheme.spacer2x,
        Text(
            '${AppLocalizations.of(context)!.comment} ( ${AppLocalizations.of(context)!.optional} )',
            style: AppTheme.labelLarge),
        AppTheme.spacer,
      ],
    );
  }

  static buildForm(PainLevelEntry? painLevelEntry) {
    return {
      'bodyPartType': FormControl<BodyPartType>(
        value: painLevelEntry?.bodyPart.type,
        validators: [Validators.required],
      ),
      'side': FormControl<Side>(
        value: painLevelEntry?.bodyPart.side ?? Side.right,
        validators: [Validators.required],
      ),
      'painLevel': FormControl<int>(
        value: painLevelEntry?.painLevel ?? 0,
        validators: [
          Validators.required,
          Validators.min(0),
          Validators.max(10)
        ],
      ),
    };
  }
}
