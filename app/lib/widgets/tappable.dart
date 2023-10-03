import 'package:flutter/material.dart';
import 'package:scimovement/theme/theme.dart';

class Tappable extends StatelessWidget {
  final Widget child;
  final Function onTap;
  final bool withDecoration;

  const Tappable({
    super.key,
    required this.child,
    required this.onTap,
    this.withDecoration = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: withDecoration ? AppTheme.widgetDecoration : null,
      child: Material(
        color: withDecoration ? AppTheme.colors.white : Colors.transparent,
        borderRadius:
            withDecoration ? AppTheme.borderRadius : BorderRadius.zero,
        clipBehavior: withDecoration ? Clip.hardEdge : Clip.none,
        child: InkWell(
          onTap: () => onTap(),
          child: child,
        ),
      ),
    );
  }
}

class TappableCircular extends StatelessWidget {
  final Widget child;
  final Function onTap;

  const TappableCircular({
    super.key,
    required this.child,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: const BorderRadius.all(Radius.circular(100)),
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: () => onTap(),
        child: child,
      ),
    );
  }
}
