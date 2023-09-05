import 'package:easy_image_viewer/easy_image_viewer.dart';
import 'package:flutter/material.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:scimovement/api/classes.dart';
import 'package:scimovement/screens/settings/widgets/form_dropdown.dart';
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
        if (entry == null || !shouldCreateEntry)
          PressureUlcerLocationSelect(form: form),
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
      'location': FormControl<PressureUlcerLocation>(
        value: pressureUlcerEntry?.location,
        validators: [Validators.required],
      ),
    };
  }
}

class PressureUlcerLocationSelect extends StatelessWidget {
  final FormGroup form;

  const PressureUlcerLocationSelect({
    super.key,
    required this.form,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            showImageViewer(
              context,
              Image.asset('assets/images/pressure_ulcer_map.png').image,
            );
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.asset('assets/images/pressure_ulcer_map.png'),
          ),
        ),
        AppTheme.spacer,
        FormDropdown(
          formKey: 'location',
          title: 'Plats',
          form: form,
          hint: AppLocalizations.of(context)!.pressureUlcerLocationHint,
          items: PressureUlcerLocation.values
              .map((location) => DropdownMenuItem(
                    value: location,
                    child: Text(
                      location.displayString(context),
                    ),
                  ))
              .toList(),
        ),
      ],
    );
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
              isDense: false,
              itemHeight: null,
              isExpanded: true,
              hint: Text(
                AppLocalizations.of(context)!.pressureUlcerClassificationHint,
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
                  .where((e) {
                    if (!showNone) {
                      return e != PressureUlcerType.none;
                    }
                    return true;
                  })
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
  final bool showDescription;

  const PressureUlcerItem({
    super.key,
    required this.type,
    this.showDescription = false,
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
