import 'package:flutter/material.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:scimovement/api/classes.dart';
import 'package:scimovement/screens/journal/widgets/body_part_select.dart';
import 'package:scimovement/theme/theme.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class PressureUlcerForm extends StatelessWidget {
  final FormGroup form;
  final PressureUlcerEntry? entry;
  final bool shouldCreateEntry;

  const PressureUlcerForm({
    super.key,
    required this.form,
    this.entry,
    this.shouldCreateEntry = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.pressureUlcerClassification,
          style: AppTheme.labelLarge,
        ),
        Text(
          AppLocalizations.of(context)!.pressureUlcerClassificationDescription,
          style: AppTheme.paragraphMedium,
        ),
        AppTheme.spacer2x,
        PressureUlcerTypeSelect(
          formKey: 'pressureUlcerType',
          showNone: entry != null || !shouldCreateEntry,
        ),
        AppTheme.spacer2x,
        if (entry == null || !shouldCreateEntry)
          Text(
            AppLocalizations.of(context)!.pressureUlcerLocation,
            style: AppTheme.labelLarge,
          ),
        if (entry == null || !shouldCreateEntry)
          Text(
            AppLocalizations.of(context)!.pressureUlcerLocationDescription,
            style: AppTheme.paragraphMedium,
          ),
        if (entry == null || !shouldCreateEntry) AppTheme.spacer2x,
        if (entry == null || !shouldCreateEntry) BodyPartSelect(form: form),
        AppTheme.spacer2x,
      ],
    );
  }

  static buildForm(
      PressureUlcerEntry? pressureUlcerEntry, bool shouldCreateEntry) {
    return {
      'pressureUlcerType': FormControl<PressureUlcerType>(
        value:
            !shouldCreateEntry ? pressureUlcerEntry?.pressureUlcerType : null,
      ),
      'bodyPartType': FormControl<BodyPartType>(
        value: pressureUlcerEntry?.bodyPart.type,
        validators: [Validators.required],
      ),
      'side': FormControl<Side>(
        value: pressureUlcerEntry?.bodyPart.side ?? Side.right,
        validators: [Validators.required],
      ),
    };
  }
}

class PressureUlcerTypeSelect extends StatelessWidget {
  final String formKey;
  final bool showNone;

  const PressureUlcerTypeSelect({
    super.key,
    required this.formKey,
    this.showNone = true,
  });

  @override
  Widget build(BuildContext context) {
    return ReactiveFormConsumer(
      builder: (BuildContext context, form, _) => SizedBox(
        width: 280,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.colors.black),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: DropdownButton(
              isDense: true,
              itemHeight: null,
              isExpanded: true,
              hint: Text(
                AppLocalizations.of(context)!.selectInjuryLevel,
                style: AppTheme.paragraphMedium,
              ),
              items: PressureUlcerType.values
                  .where((e) {
                    if (!showNone) {
                      return e != PressureUlcerType.none;
                    }
                    return true;
                  })
                  .map((e) => _dropdownItem(context, e))
                  .toList(),
              value: form.control(formKey).value,
              onChanged: (value) {
                form.control(formKey).value = value;
              },
              icon:
                  Icon(Icons.keyboard_arrow_down, color: AppTheme.colors.black),
              underline: Container(),
              selectedItemBuilder: (context) => PressureUlcerType.values
                  .map((e) => _dropdownItem(context, e, true))
                  .toList(),
            ),
          ),
        ),
      ),
    );
  }

  DropdownMenuItem<PressureUlcerType> _dropdownItem(
      BuildContext context, PressureUlcerType type,
      [bool selected = false]) {
    return DropdownMenuItem(
      value: type,
      child: PressureUlcerItem(type: type, showDescription: selected),
    );
  }
}

class PressureUlcerItem extends StatelessWidget {
  final PressureUlcerType type;
  final BodyPart? bodyPart;
  final bool showDescription;

  const PressureUlcerItem({
    super.key,
    required this.type,
    this.showDescription = false,
    this.bodyPart,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: type.color,
                borderRadius: BorderRadius.circular(6),
                border:
                    Border.all(color: AppTheme.colors.black.withOpacity(0.1)),
              ),
            ),
            AppTheme.spacer,
            Text(
              type.displayString(context),
              style: AppTheme.labelLarge,
            ),
          ],
        ),
        if (!showDescription) AppTheme.spacer,
        if (!showDescription)
          Text(
            type.description(context),
            style: AppTheme.paragraphMedium,
          ),
        if (!showDescription) AppTheme.separator,
      ],
    );
  }
}
