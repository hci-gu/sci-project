import 'package:flutter/material.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:scimovement/api/classes/journal/bowel_emptying.dart';
import 'package:scimovement/theme/theme.dart';
import 'package:scimovement/gen_l10n/app_localizations.dart';

class BowelEmptyingForm extends StatelessWidget {
  final FormGroup form;
  final BowelEmptyingEntry? entry;
  final bool shouldCreateEntry;

  const BowelEmptyingForm({
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
          AppLocalizations.of(context)!.stoolType,
          style: AppTheme.labelLarge,
        ),
        Text(
          AppLocalizations.of(context)!.stoolTypeHint,
          style: AppTheme.paragraphMedium,
        ),
        AppTheme.spacer,
        const StoolTypeSelect(
          formKey: 'stoolType',
        ),
        AppTheme.spacer2x,
      ],
    );
  }

  static Map<String, FormControl> buildForm(
      BowelEmptyingEntry? entry, bool shouldCreateEntry) {
    return {
      'stoolType': FormControl<StoolType>(
        value: entry != null && !shouldCreateEntry ? entry.stoolType : null,
      ),
    };
  }
}

class StoolTypeSelect extends StatelessWidget {
  final String formKey;
  final bool showNone;

  const StoolTypeSelect({
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
                AppLocalizations.of(context)!.stoolType,
                style: AppTheme.paragraphMedium,
              ),
              items: StoolType.values
                  .map((e) => _dropdownItem(context, e))
                  .toList(),
              value: form.control(formKey).value,
              onChanged: (value) {
                form.control(formKey).value = value;
              },
              icon:
                  Icon(Icons.keyboard_arrow_down, color: AppTheme.colors.black),
              underline: Container(),
              selectedItemBuilder: (context) => StoolType.values
                  .map((e) => _dropdownItem(context, e, true))
                  .toList(),
            ),
          ),
        ),
      ),
    );
  }

  DropdownMenuItem<StoolType> _dropdownItem(
      BuildContext context, StoolType type,
      [bool selected = false]) {
    return DropdownMenuItem(
      value: type,
      child: StoolTypeItem(type: type, showDescription: !selected),
    );
  }
}

class StoolTypeItem extends StatelessWidget {
  final StoolType type;
  final bool showDescription;

  const StoolTypeItem({
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
            image,
            AppTheme.spacer,
            Text(
              type.displayString(context),
              style: AppTheme.labelLarge,
            ),
          ],
        ),
        if (showDescription)
          Text(
            type.description(context),
            style: AppTheme.paragraphMedium,
            maxLines: 2,
          ),
        if (showDescription) AppTheme.separator,
      ],
    );
  }

  Widget get image {
    return Image.asset('assets/images/stool_${type.name}.png', width: 50);
  }
}
