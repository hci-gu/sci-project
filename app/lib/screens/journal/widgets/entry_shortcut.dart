import 'package:flutter/material.dart';
import 'package:scimovement/theme/theme.dart';

class JournalEntryShortcut extends StatelessWidget {
  final Function onTap;
  final Widget icon;
  final String title;
  final String? subtitle;

  const JournalEntryShortcut({
    super.key,
    required this.onTap,
    required this.icon,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(),
      child: Container(
        decoration: AppTheme.widgetDecoration,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              icon,
              AppTheme.spacer,
              FittedBox(
                child: Text(
                  title,
                  style: AppTheme.labelMedium,
                  textAlign: TextAlign.center,
                ),
              ),
              if (subtitle != null)
                FittedBox(
                  child: Text(
                    subtitle!,
                    style: AppTheme.paragraphSmall,
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
