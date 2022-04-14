import 'package:flutter/material.dart';

class ChartWrapper extends StatelessWidget {
  final Widget child;
  final bool loading;
  final bool isEmpty;
  final double aspectRatio;

  const ChartWrapper({
    Key? key,
    required this.child,
    required this.loading,
    required this.isEmpty,
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
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: const Color(0xff232d37),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              offset: const Offset(0, 4),
              blurRadius: 30,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.only(
            left: 12,
            right: 24,
            top: 16,
            bottom: 4,
          ),
          child: child,
        ),
      ),
    );
  }
}
