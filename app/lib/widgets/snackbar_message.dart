import 'package:flutter/material.dart';
import 'package:scimovement/theme/theme.dart';

enum SnackbarType {
  error,
  success,
}

class SnackbarMessage extends SnackBar {
  final BuildContext context;
  final String message;
  final SnackbarType type;

  SnackbarMessage({
    Key? key,
    required this.context,
    required this.message,
    this.type = SnackbarType.success,
  }) : super(
          key: key,
          content: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(type == SnackbarType.success ? Icons.check : Icons.error,
                  color: AppTheme.colors.white),
              AppTheme.spacer,
              SizedBox(
                // dynamic width
                width: MediaQuery.of(context).size.width * 0.6,
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  style: AppTheme.labelLarge,
                ),
              ),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          backgroundColor: type == SnackbarType.success
              ? AppTheme.colors.success
              : AppTheme.colors.error,
        );
}
