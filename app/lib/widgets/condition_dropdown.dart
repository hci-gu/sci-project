import 'package:flutter/material.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:scimovement/theme/theme.dart';

class ConditionDropdown extends StatelessWidget {
  final String formKey;
  final String hint;
  final bool showNone;
  final List<DropdownMenuItem<Object>>? items;
  final List<Widget> Function(BuildContext)? selectedItemBuilder;

  const ConditionDropdown({
    super.key,
    required this.formKey,
    required this.hint,
    this.showNone = true,
    this.items = const [],
    this.selectedItemBuilder,
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
              hint: Text(hint, style: AppTheme.paragraphMedium),
              items: items,
              value: form.control(formKey).value,
              onChanged: (value) {
                form.control(formKey).value = value;
              },
              icon: Icon(
                Icons.keyboard_arrow_down,
                color: AppTheme.colors.black,
              ),
              underline: Container(),
              selectedItemBuilder: selectedItemBuilder,
            ),
          ),
        ),
      ),
    );
  }
}
