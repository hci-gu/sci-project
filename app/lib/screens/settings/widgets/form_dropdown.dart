import 'package:flutter/material.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:scimovement/theme/theme.dart';

class FormDropdown extends StatelessWidget {
  final String formKey;
  final String title;
  final FormGroup form;
  final List<DropdownMenuItem> items;
  final String hint;
  final bool readOnly;

  const FormDropdown({
    Key? key,
    required this.formKey,
    required this.title,
    required this.form,
    this.hint = 'Välj typ',
    this.readOnly = false,
    this.items = const [],
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ReactiveDropdownField<dynamic>(
      formControlName: formKey,
      hint: Text(hint),
      icon: const Icon(Icons.keyboard_arrow_down),
      iconSize: 24,
      isDense: false,
      readOnly: readOnly,
      selectedItemBuilder: (_) {
        return items
            .map(
              (i) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTheme.labelTiny,
                  ),
                  i.child,
                ],
              ),
            )
            .toList();
      },
      decoration: InputDecoration(
        isDense: true,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4.0),
          borderSide: const BorderSide(
            color: Color.fromRGBO(0, 0, 0, 0.1),
            width: 1,
          ),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4.0),
          borderSide: const BorderSide(
            color: Color.fromRGBO(0, 255, 0, 0.1),
            width: 1,
          ),
        ),
      ),
      items: items,
    );
  }
}
