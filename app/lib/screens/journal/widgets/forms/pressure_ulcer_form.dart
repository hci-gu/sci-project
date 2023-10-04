import 'package:easy_image_viewer/easy_image_viewer.dart';
import 'package:flutter/material.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:scimovement/api/classes/journal/journal.dart';
import 'package:scimovement/screens/settings/widgets/form_dropdown.dart';
import 'package:scimovement/theme/theme.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:scimovement/widgets/condition_dropdown.dart';
import 'package:scimovement/widgets/condition_item.dart';
import 'package:scimovement/widgets/condition_select.dart';

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
        ConditionDropdown(
          formKey: 'pressureUlcerType',
          hint: AppLocalizations.of(context)!.pressureUlcerClassificationHint,
          items: PressureUlcerType.values
              .map((e) => _dropdownItem(context, e))
              .toList(),
          selectedItemBuilder: (context) => PressureUlcerType.values
              .map((e) => _dropdownItem(context, e, true))
              .toList(),
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

  DropdownMenuItem<PressureUlcerType> _dropdownItem(
      BuildContext context, PressureUlcerType type,
      [bool showDescription = false]) {
    return DropdownMenuItem(
      value: type,
      child: ConditionItem(
        display: ConditionDisplay(
          title: type.displayString(context),
          subtitle: type.description(context),
          color: type.color,
        ),
        showDescription: showDescription,
      ),
    );
  }

  static buildForm(
      PressureUlcerEntry? pressureUlcerEntry, bool shouldCreateEntry) {
    return {
      'pressureUlcerType': FormControl<PressureUlcerType>(
        value:
            !shouldCreateEntry ? pressureUlcerEntry?.pressureUlcerType : null,
        validators: [Validators.required],
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
