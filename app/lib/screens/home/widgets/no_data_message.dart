import 'package:flutter/material.dart';

class NoDataMessage extends StatelessWidget {
  const NoDataMessage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Inga data',
        style: Theme.of(context).textTheme.headline6,
      ),
    );
  }
}
