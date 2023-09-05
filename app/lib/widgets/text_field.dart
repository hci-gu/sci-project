import 'package:flutter/material.dart';
import 'package:reactive_forms/reactive_forms.dart';

class StyledTextField extends StatelessWidget {
  final String formControlName;
  final String placeholder;
  final String? helperText;
  final bool obscureText;
  final bool disabled;
  final int? minLines;
  final int? maxLines;
  final Function onTap;
  final bool canClear;
  final bool canEdit;
  final Widget? icon;
  final TextInputType? keyboardType;

  const StyledTextField({
    Key? key,
    required this.formControlName,
    required this.placeholder,
    this.helperText,
    this.obscureText = false,
    this.disabled = false,
    this.minLines,
    this.maxLines = 1,
    this.onTap = _noop,
    this.canClear = false,
    this.canEdit = true,
    this.icon,
    this.keyboardType,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
      absorbing: disabled,
      child: Opacity(
        opacity: disabled ? 0.5 : 1,
        child: ReactiveTextField(
          textInputAction: TextInputAction.next,
          formControlName: formControlName,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            prefixIcon: icon,
            suffixIcon: canClear ? _clearButton() : null,
            labelText: placeholder,
            helperText: helperText,
            helperMaxLines: maxLines,
            border: const OutlineInputBorder(),
            isDense: true,
          ),
          minLines: minLines,
          maxLines: maxLines,
          obscureText: obscureText,
          readOnly: disabled || !canEdit,
          onTap: (_) => onTap(),
          validationMessages: {
            ValidationMessage.required: (_) => 'Fältet är obligatoriskt',
            ValidationMessage.email: (_) => 'Måste vara en giltig e-postadress',
            ValidationMessage.minLength: (_) => 'Måste vara minst 8 tecken',
            ValidationMessage.mustMatch: (_) => 'Lösenorden måste matcha',
          },
        ),
      ),
    );
  }

  Widget _clearButton() {
    return ReactiveValueListenableBuilder(
      formControlName: formControlName,
      builder: (context, fg, child) {
        return IconButton(
          onPressed: () => fg.updateValue(null),
          icon: const Icon(Icons.cancel_outlined),
        );
      },
    );
  }

  static dynamic _noop() {}
}
