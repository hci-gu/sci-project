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
    super.key,
    required this.context,
    required this.message,
    this.type = SnackbarType.success,
  }) : super(
          content: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(type == SnackbarType.success ? Icons.check : Icons.error,
                  color: AppTheme.colors.white),
              AppTheme.spacer,
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.6,
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  style: AppTheme.labelLarge.copyWith(
                    color: AppTheme.colors.white,
                  ),
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
