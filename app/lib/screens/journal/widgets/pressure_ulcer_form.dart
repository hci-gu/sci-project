import 'package:flutter/material.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:scimovement/api/classes.dart';
import 'package:scimovement/screens/journal/widgets/body_part_select.dart';
import 'package:scimovement/theme/theme.dart';

class PressureUlcerForm extends StatelessWidget {
  final FormGroup form;
  final bool shouldCreateEntry;

  const PressureUlcerForm({
    super.key,
    required this.form,
    this.shouldCreateEntry = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Trycksårsklassificering',
          style: AppTheme.labelLarge,
        ),
        Text(
          'Välj den nivå av skada som ditt trycksår har nu.',
          style: AppTheme.paragraphMedium,
        ),
        AppTheme.spacer2x,
        const PressureUlcerTypeSelect(formKey: 'pressureUlcerType'),
        AppTheme.spacer2x,
        if (shouldCreateEntry)
          Text(
            'Var är ditt sår någonstans?',
            style: AppTheme.labelLarge,
          ),
        if (shouldCreateEntry)
          Text(
            'Välj den plats på kroppen där ditt trycksår finns.',
            style: AppTheme.paragraphMedium,
          ),
        if (shouldCreateEntry) AppTheme.spacer2x,
        if (shouldCreateEntry) BodyPartSelect(form: form),
        AppTheme.spacer2x,
      ],
    );
  }

  static buildForm(
      PressureUlcerEntry? pressureUlcerEntry, bool shouldCreateEntry) {
    return {
      'pressureUlcerType': FormControl<PressureUlcerType>(
        value: shouldCreateEntry ? pressureUlcerEntry?.pressureUlcerType : null,
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

  const PressureUlcerTypeSelect({super.key, required this.formKey});

  @override
  Widget build(BuildContext context) {
    return ReactiveFormConsumer(
      builder: (BuildContext context, form, _) => SizedBox(
        width: 200,
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
                'Välj skadenivå',
                style: AppTheme.paragraphMedium,
              ),
              items: PressureUlcerType.values
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