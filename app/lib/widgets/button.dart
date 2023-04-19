import 'package:flutter/material.dart';
import 'package:scimovement/theme/theme.dart';

enum ButtonSize {
  tiny,
  small,
  medium,
  large,
}

extension SizeToFloat on ButtonSize {
  double get height {
    switch (this) {
      case ButtonSize.tiny:
        return 28;
      case ButtonSize.small:
        return 34;
      case ButtonSize.medium:
        return 44;
      case ButtonSize.large:
        return 48;
      default:
        return 44;
    }
  }

  double get fontSize {
    switch (this) {
      case ButtonSize.tiny:
      case ButtonSize.small:
        return 12;
      case ButtonSize.medium:
        return 16;
      case ButtonSize.large:
        return 18;
      default:
        return 16;
    }
  }

  FontWeight get fontWeight {
    switch (this) {
      case ButtonSize.tiny:
      case ButtonSize.small:
        return FontWeight.w500;
      case ButtonSize.medium:
        return FontWeight.w800;
      case ButtonSize.large:
        return FontWeight.w800;
      default:
        return FontWeight.w800;
    }
  }
}

class Button extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final VoidCallback onPressed;
  final IconData? icon;
  final double? width;
  final ButtonSize size;
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
    this.subtitle,
    this.icon,
    this.width,
    this.color,
    this.size = ButtonSize.medium,
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
        rounded: rounded, secondary: secondary, size: size, color: color);
    Widget _text = Text(
      title ?? '',
      style: AppTheme.buttonTextStyle(secondary, color, size),
    );
    if (subtitle != null) {
      _text = FittedBox(
        fit: BoxFit.contain,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _text,
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                subtitle ?? '',
                style: AppTheme.buttonTextStyle(secondary, color, size),
              ),
            ),
          ],
        ),
      );
    }

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
        child: loading ? loadingIndicator : _text,
      );
    }

    return AbsorbPointer(
      absorbing: disabled || loading,
      child: width != null
          ? SizedBox(
              width: width,
              child: button,
              height: size.height,
            )
          : SizedBox(
              width: width,
              child: button,
              height: size.height,
            ),
    );
  }
}
