import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:scimovement/widgets/button.dart';

class NumberSlider extends StatelessWidget {
  final GlobalKey _key = GlobalKey();
  final String formKey;

  NumberSlider({
    Key? key,
    required this.formKey,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ReactiveValueListenableBuilder<int?>(
      formControlName: formKey,
      builder: (context, fg, child) {
        return Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Button(
                width: 34,
                icon: Icons.remove,
                onPressed: () {
                  if (fg.value != null && fg.value! > 0) {
                    fg.updateValue(fg.value != null ? fg.value! - 1 : 0);
                  }
                },
                size: ButtonSize.small,
              ),
              const SizedBox(width: 8),
              const Text(
                '0',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              Expanded(
                child: Stack(clipBehavior: Clip.none, children: [
                  PositionedSliderLabel(
                    positionKey: _key,
                    value: fg.value,
                  ),
                  Positioned(
                    child: ReactiveSlider(
                      key: _key,
                      formControlName: formKey,
                      min: 0,
                      max: 10,
                    ),
                  ),
                ]),
              ),
              const Text(
                '10',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 8),
              Button(
                width: 34,
                size: ButtonSize.small,
                icon: Icons.add,
                onPressed: () {
                  if (fg.value == null) {
                    fg.updateValue(0);
                    return;
                  }
                  if (fg.value! < 10) {
                    fg.updateValue(fg.value! + 1);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class PositionedSliderLabel extends HookWidget {
  final int? value;
  final GlobalKey positionKey;

  const PositionedSliderLabel({
    Key? key,
    this.value,
    required this.positionKey,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var state = useState(null);
    useEffect(() {
      Future.delayed(const Duration(milliseconds: 25)).then((value) {
        state.notifyListeners();
      });
      return () => {};
    }, []);

    return Positioned(
      top: -12,
      left: _getValuePosition(value?.toDouble() ?? 0),
      child: value != null
          ? FittedBox(
              fit: BoxFit.contain,
              child: SizedBox(
                width: 30,
                child: Text(
                  value?.toString() ?? '0',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            )
          : Container(),
    );
  }

  double _getValuePosition(double value) {
    if (positionKey.currentContext == null) {
      return 1;
    }
    RenderBox box = positionKey.currentContext!.findRenderObject() as RenderBox;

    var valueRangeSize = 11;
    var valuePercent = (value + 1) / valueRangeSize;
    var offset = (box.size.width - 30) * valuePercent;

    return offset;
  }
}
