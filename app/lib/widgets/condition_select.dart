import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scimovement/theme/theme.dart';

class ConditionDisplay {
  final String title;
  final String? subtitle;
  final Color? color;

  const ConditionDisplay({
    required this.title,
    required this.subtitle,
    required this.color,
  });
}

class ConditionSelect extends ConsumerWidget {
  final FutureProvider<ConditionDisplay> provider;
  final Widget modal;
  final Widget? button;

  const ConditionSelect({
    super.key,
    required this.provider,
    required this.modal,
    this.button,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(provider).when(
          data: (data) => GestureDetector(
            onTap: () => _openModal(context),
            child: _body(
              _row(context, data),
            ),
          ),
          error: (_, __) => _body(const Text('error')),
          loading: () => _body(
            const Center(child: CircularProgressIndicator()),
          ),
        );
  }

  Widget _row(BuildContext context, ConditionDisplay display) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                      ),
                    ),
                  if (display.color != null) AppTheme.spacerHalf,
                  Expanded(
                    child: AutoSizeText(
                      display.title,
                      style: AppTheme.labelLarge,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
              if (display.subtitle != null)
                Expanded(
                  child: AutoSizeText(
                    display.subtitle!,
                    style: AppTheme.paragraphSmall,
                    maxLines: 2,
                  ),
                ),
            ],
          ),
        ),
        const Icon(Icons.keyboard_arrow_down)
      ],
    );
  }

  Widget _body(Widget child) {
    return Container(
      height: 60,
      decoration: AppTheme.widgetDecoration.copyWith(
        borderRadius: const BorderRadius.all(Radius.circular(12)),
      ),
      padding: const EdgeInsets.only(left: 8, top: 8, bottom: 0, right: 2),
      child: child,
    );
  }

  void _openModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
      ),
      elevation: 4,
      isScrollControlled: true,
      clipBehavior: Clip.hardEdge,
      builder: (context) => Wrap(
        children: [
          Padding(
            padding: AppTheme.elementPadding,
            child: modal,
          )
        ],
      ),
    );
  }
}
