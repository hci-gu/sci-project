import 'package:flutter/material.dart';
import 'package:scimovement/theme/theme.dart';
import 'package:scimovement/widgets/condition_select.dart';

class ConditionItem extends StatelessWidget {
  final ConditionDisplay display;
  final bool showDescription;
  final Widget? button;

  const ConditionItem({
    super.key,
    required this.display,
    this.showDescription = false,
    this.button,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (display.color != null)
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: display.color,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: AppTheme.colors.black.withOpacity(0.1)),
                      ),
                    ),
                  if (display.color != null) AppTheme.spacer,
                  Text(
                    display.title,
                    style: AppTheme.labelLarge,
                  ),
                ],
              ),
              if (!showDescription) AppTheme.spacer,
              if (!showDescription)
                Text(
                  display.subtitle ?? '',
                  style: AppTheme.paragraphMedium,
                ),
              if (!showDescription) AppTheme.separator,
            ],
          ),
        ),
        if (button != null) button!,
      ],
    );
  }
}
