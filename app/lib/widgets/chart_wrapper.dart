import 'package:flutter/material.dart';

class ChartWrapper extends StatelessWidget {
  final Widget child;
  final bool loading;
  final bool isEmpty;
  final bool isCard;
  final double aspectRatio;

  const ChartWrapper({
    Key? key,
    required this.child,
    required this.loading,
    required this.isEmpty,
    this.isCard = true,
    this.aspectRatio = 1.7,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget widgetToDisplay = child;

    if (loading) {
      widgetToDisplay = const Center(
        child: CircularProgressIndicator(),
      );
    } else if (isEmpty) {
      widgetToDisplay = const Center(
        child: Text(
          'No data',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
      );
    }
    return _wrapper(widgetToDisplay);
  }

  Widget _wrapper(Widget child) {
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: Container(
        height: 300,
        decoration: isCard
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: const Color.fromRGBO(0, 0, 0, 0.1),
                  width: 1,
                ),
              )
            : null,
        child: Padding(
          padding:
              const EdgeInsets.only(left: 8, right: 24, top: 24, bottom: 24),
          child: child,
        ),
      ),
    );
  }
}
