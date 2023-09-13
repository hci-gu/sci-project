import 'package:easy_image_viewer/easy_image_viewer.dart';
import 'package:flutter/material.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:scimovement/api/classes.dart';
import 'package:scimovement/screens/settings/widgets/form_dropdown.dart';
import 'package:scimovement/theme/theme.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class BladderEmptyingForm extends StatelessWidget {
  final FormGroup form;
  final BladderEmptyingEntry? entry;
  final bool shouldCreateEntry;

  const BladderEmptyingForm({
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
          'Urin',
          style: AppTheme.labelLarge,
        ),
        Text(
          'Välj det alternativ som beskriver urinet.',
          style: AppTheme.paragraphMedium,
        ),
        AppTheme.spacer,
        const UrineTypeSelect(
          formKey: 'urineType',
        ),
        AppTheme.spacer2x,
        Text(
          'Luktar det?',
          style: AppTheme.labelLarge,
        ),
        Text(
          'Lukt kan vara ett tecken på en infektion.',
          style: AppTheme.paragraphMedium,
        ),
        AppTheme.spacer,
        const RadioRow(
          formKey: 'smell',
          yesText: 'Ja det luktar',
          noText: 'Nej det luktar inte',
        ),
        AppTheme.spacer2x,
      ],
    );
  }

  static buildForm(BladderEmptyingEntry? entry, bool shouldCreateEntry) {
    return {
      'urineType': FormControl<UrineType>(
        value: entry != null && !shouldCreateEntry
            ? entry.urineType
            : UrineType.normal,
      ),
      'smell': FormControl<bool>(
        value: entry != null && !shouldCreateEntry ? entry.smell : false,
      ),
    };
  }
}

class UrineTypeSelect extends StatelessWidget {
  final String formKey;
  final bool showNone;

  const UrineTypeSelect({
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
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: DropdownButton(
              isDense: false,
              itemHeight: null,
              isExpanded: true,
              hint: Text(
                'Urintyp',
                style: AppTheme.paragraphMedium,
              ),
              items: UrineType.values
                  .map((e) => _dropdownItem(context, e))
                  .toList(),
              value: form.control(formKey).value,
              onChanged: (value) {
                form.control(formKey).value = value;
              },
              icon:
                  Icon(Icons.keyboard_arrow_down, color: AppTheme.colors.black),
              underline: Container(),
              selectedItemBuilder: (context) => UrineType.values
                  .map((e) => _dropdownItem(context, e, true))
                  .toList(),
            ),
          ),
        ),
      ),
    );
  }

  DropdownMenuItem<UrineType> _dropdownItem(
      BuildContext context, UrineType type,
      [bool selected = false]) {
    return DropdownMenuItem(
      value: type,
      child: UrineTypeItem(type: type, showDescription: selected),
    );
  }
}

class UrineTypeItem extends StatelessWidget {
  final UrineType type;
  final bool showDescription;

  const UrineTypeItem({
    super.key,
    required this.type,
    this.showDescription = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          type.displayString(context),
          style: AppTheme.labelLarge,
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

class RadioRow extends StatelessWidget {
  final String formKey;
  final String yesText;
  final String noText;

  const RadioRow(
      {super.key,
      required this.formKey,
      required this.yesText,
      required this.noText});

  @override
  Widget build(BuildContext context) {
    return ReactiveFormConsumer(
      builder: (BuildContext context, form, _) => Row(
        children: [
          GestureDetector(
            onTap: () {
              form.control(formKey).value = true;
            },
            behavior: HitTestBehavior.translucent,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: AppTheme.basePadding),
              child: Row(
                children: [
                  Radio(
                    value: form.control(formKey).value as bool,
                    groupValue: true,
                    onChanged: (_) => {},
                  ),
                  AppTheme.spacer,
                  Text(yesText, style: AppTheme.paragraphMedium),
                ],
              ),
            ),
          ),
          AppTheme.spacer,
          GestureDetector(
            onTap: () {
              form.control(formKey).value = false;
            },
            behavior: HitTestBehavior.translucent,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: AppTheme.basePadding),
              child: Row(
                children: [
                  Radio(
                    value: form.control(formKey).value as bool,
                    groupValue: false,
                    onChanged: (_) {},
                  ),
                  AppTheme.spacer,
                  Text(noText, style: AppTheme.paragraphMedium),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
