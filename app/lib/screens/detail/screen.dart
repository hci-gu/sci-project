import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scimovement/models/config.dart';
import 'package:scimovement/theme/theme.dart';
import 'package:scimovement/widgets/chart_mode_select.dart';
import 'package:scimovement/widgets/stat_header.dart';
import 'package:swipe/swipe.dart';

class DetailScreen extends ConsumerWidget {
  final String title;
  final Widget body;
  final StatHeader header;

  const DetailScreen({
    Key? key,
    required this.title,
    required this.body,
    required this.header,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppTheme.appBar(title),
      body: Swipe(
        onSwipeLeft: () {
          Pagination pagination = ref.read(paginationProvider);
          ref.read(paginationProvider.notifier).state = Pagination(
            page: max(pagination.page - 1, 0),
            mode: pagination.mode,
          );
        },
        onSwipeRight: () {
          Pagination pagination = ref.read(paginationProvider);
          ref.read(paginationProvider.notifier).state = Pagination(
            page: pagination.page + 1,
            mode: pagination.mode,
          );
        },
        child: Padding(
          padding: AppTheme.screenPadding,
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [header, const ChartModeSelect()],
              ),
              body,
            ],
          ),
        ),
      ),
    );
  }

  static Widget separator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Container(
        height: 1,
        color: const Color.fromRGBO(0, 0, 0, 0.1),
      ),
    );
  }
}
