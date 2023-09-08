import 'package:flutter/material.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:scimovement/api/classes.dart';
import 'package:scimovement/theme/theme.dart';

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
        Text(
          'Urin',
          style: AppTheme.labelLarge,
        ),
        Text(
          'Välj det alternativ som beskriver urinet.',
          style: AppTheme.paragraphMedium,
        ),
        AppTheme.spacer2x,
      ],
    );
  }

  static buildForm(UTIEntry? entry, bool shouldCreateEntry) {
    return {};
  }
}
