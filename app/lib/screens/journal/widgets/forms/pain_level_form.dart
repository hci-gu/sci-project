import 'package:flutter/material.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:scimovement/api/classes.dart';
import 'package:scimovement/api/classes/journal/journal.dart';
import 'package:scimovement/screens/journal/widgets/body_part_select.dart';
import 'package:scimovement/screens/journal/widgets/number_slider.dart';
import 'package:scimovement/theme/theme.dart';
import 'package:scimovement/gen_l10n/app_localizations.dart';

class PainLevelForm extends StatelessWidget {
  final PainLevelEntry? entry;
  final JournalType? type;
  final FormGroup form;

  const PainLevelForm({
    super.key,
    this.entry,
    this.type,
    required this.form,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (entry == null)
          BodyPartSelect(form: form, type: type ?? JournalType.musclePain),
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
        NumberSlider(formKey: 'painLevel'),
        AppTheme.spacer2x,
      ],
    );
  }

  static Map<String, FormControl> buildForm(
      PainLevelEntry? painLevelEntry, JournalType? type) {
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
