import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:scimovement/theme/theme.dart';
import 'package:scimovement/widgets/button.dart';

class DurationPicker extends HookWidget {
  final String? title;
  final Color? titleColor;
  final Duration value;
  final Function onChange;
  final bool readOnly;

  const DurationPicker({
    Key? key,
    required this.value,
    required this.onChange,
    this.title,
    this.titleColor,
    this.readOnly = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    FocusNode _focusNode = useFocusNode();

    return Focus(
      focusNode: _focusNode,
      onFocusChange: (focused) {
        if (focused && !readOnly) {
          _showDurationPicker(context);
          onChange(value);
          Scrollable.ensureVisible(
            _focusNode.context!,
            duration: const Duration(milliseconds: 250),
          );
        }
      },
      child: Padding(
        padding: EdgeInsets.only(top: AppTheme.basePadding * 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            if (title != null) _title(context),
            Button(
              width: 34,
              icon: Icons.remove,
              onPressed: () {
                if (value.inMinutes >= 15) {
                  onChange(Duration(minutes: value.inMinutes - 15));
                }
              },
              disabled: readOnly,
              size: ButtonSize.small,
            ),
            AppTheme.spacer,
            GestureDetector(
              onTap: () {
                if (readOnly) return;
                _focusNode.requestFocus();
              },
              child: DurationDisplay(
                duration: value,
                highlighted: _focusNode.hasFocus,
              ),
            ),
            AppTheme.spacer,
            Button(
              width: 34,
              icon: Icons.add,
              onPressed: () {
                onChange(Duration(minutes: value.inMinutes + 15));
              },
              size: ButtonSize.small,
              disabled: readOnly,
            ),
          ],
        ),
      ),
    );
  }

  Widget _title(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            title!,
            style: const TextStyle(fontSize: 16),
          ),
        ),
        const SizedBox(height: 2),
        SizedBox(
          width: 30,
          height: 3,
          child: Container(color: titleColor ?? AppTheme.colors.primary),
        )
      ],
    );
  }

  void _showDurationPicker(BuildContext context) {
    showBottomSheet(
      elevation: 24,
      context: context,
      builder: (BuildContext ctx) {
        return Container(
          height: 275,
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.black.withAlpha(100),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: AppTheme.elementPadding,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Button(
                      title: 'Stäng',
                      onPressed: () {
                        Navigator.pop(ctx);
                      },
                      width: 100,
                      size: ButtonSize.small,
                    ),
                  ],
                ),
                CupertinoTimerPicker(
                  initialTimerDuration: value,
                  mode: CupertinoTimerPickerMode.hm,
                  minuteInterval: 15,
                  onTimerDurationChanged: (value) {
                    onChange(value);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class DurationDisplay extends StatelessWidget {
  final Duration duration;
  final bool highlighted;

  const DurationDisplay({
    Key? key,
    required this.duration,
    this.highlighted = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String hours = duration.toString().split(':')[0];
    String minutes = duration.toString().split(':')[1];

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: highlighted ? AppTheme.colors.primaryDark : Colors.black,
          width: highlighted ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      width: 80,
      height: 44,
      child: Padding(
        padding: AppTheme.elementPadding,
        child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text(
                hours.length == 1 ? '0$hours' : hours,
                style: AppTheme.labelMedium,
              ),
              const Text(':'),
              Text(
                minutes,
                style: AppTheme.labelMedium,
              ),
            ]),
      ),
    );
  }
}
