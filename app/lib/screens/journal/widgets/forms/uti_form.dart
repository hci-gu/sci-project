import 'package:flutter/material.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:scimovement/api/classes/journal/journal.dart';
import 'package:scimovement/theme/theme.dart';
import 'package:scimovement/widgets/condition_dropdown.dart';
import 'package:scimovement/widgets/condition_item.dart';
import 'package:scimovement/widgets/condition_select.dart';

class UTIForm extends StatelessWidget {
  final FormGroup form;
  final UTIEntry? entry;
  final bool shouldCreateEntry;

  const UTIForm({
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
        ConditionDropdown(
          formKey: 'utiType',
          hint: 'Hint',
          items: UTIType.values.map((e) => _dropdownItem(context, e)).toList(),
          selectedItemBuilder: (context) => UTIType.values
              .map((e) => _dropdownItem(context, e, true))
              .toList(),
        ),
        AppTheme.spacer2x,
      ],
    );
  }

  DropdownMenuItem<UTIType> _dropdownItem(BuildContext context, UTIType type,
      [bool showDescription = false]) {
    return DropdownMenuItem(
      value: type,
      child: ConditionItem(
        display: ConditionDisplay(
          title: type.displayString(context),
          subtitle: type.description(context),
          color: type.color(),
        ),
        showDescription: showDescription,
      ),
    );
  }

  static buildForm(UTIEntry? entry, bool shouldCreateEntry) {
    return {
      'utiType': FormControl<UTIType>(
        value: entry?.utiType,
      ),
    };
  }
}
