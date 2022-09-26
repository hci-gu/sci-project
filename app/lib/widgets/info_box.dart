import 'package:flutter/material.dart';
import 'package:scimovement/theme/theme.dart';

class InfoBox extends StatelessWidget {
  final String title;
  final String text;

  const InfoBox({
    Key? key,
    required this.title,
    required this.text,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: AppTheme.labelLarge),
        AppTheme.spacer,
        DecoratedBox(
          decoration: AppTheme.cardDecoration,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Text(
              text,
              style: AppTheme.paragraphMedium,
            ),
          ),
        ),
      ],
    );
  }
}
