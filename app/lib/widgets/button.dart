import 'package:flutter/material.dart';
import 'package:scimovement/theme/theme.dart';

class Button extends StatelessWidget {
  final String? title;
  final VoidCallback onPressed;
  final IconData? icon;
  final double? width;
  final bool small;
  final bool rounded;
  final bool secondary;
  final bool flipIcon;
  final bool disabled;
  final bool loading;
  late Color? color;

  Button({
    Key? key,
    required this.onPressed,
    this.title,
    this.icon,
    this.width,
    this.color,
    this.small = false,
    this.rounded = true,
    this.secondary = false,
    this.flipIcon = false,
    this.disabled = false,
    this.loading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget button;
    color ??= AppTheme.primarySwatch;
    if (disabled) {
      color = Colors.grey;
    }
    Widget loadingIndicator = Center(
      child: SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 3,
          color: secondary ? AppTheme.primarySwatch : AppTheme.colors.white,
        ),
      ),
    );

    ButtonStyle style = AppTheme.buttonStyle(
        rounded: rounded, secondary: secondary, small: small, color: color);

    if (icon != null) {
      Widget _icon =
          Icon(icon, color: secondary ? color : AppTheme.colors.white);
      if (title == null) {
        button = TextButton(
          style: style,
          onPressed: onPressed,
          child: loading ? loadingIndicator : _icon,
        );
      } else {
        Widget _text = Text(title ?? '',
            style: AppTheme.buttonTextStyle(secondary, color, small));
        button = TextButton.icon(
          style: style,
          onPressed: onPressed,
          icon: loading
              ? loadingIndicator
              : flipIcon
                  ? _text
                  : _icon,
          label: flipIcon ? _icon : _text,
        );
      }
    } else {
      button = TextButton(
        style: style,
        onPressed: onPressed,
        child: loading
            ? loadingIndicator
            : Text(
                title ?? '',
                style: AppTheme.buttonTextStyle(secondary, color, small),
              ),
      );
    }

    return AbsorbPointer(
      absorbing: disabled || loading,
      child: width != null
          ? Center(
              child: SizedBox(
                width: width,
                child: button,
                height: small ? 34 : 44,
              ),
            )
          : SizedBox(
              width: width,
              child: button,
              height: small ? 34 : 44,
            ),
    );
  }
}
