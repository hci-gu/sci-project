import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scimovement/models/pagination.dart';
import 'package:scimovement/theme/theme.dart';
import 'package:scimovement/widgets/chart_mode_select.dart';
import 'package:scimovement/widgets/info_box.dart';
import 'package:scimovement/widgets/stat_header.dart';

typedef PageBuilder = Widget Function(BuildContext context, int page);

class DetailScreen extends HookConsumerWidget {
  final String title;
  final PageBuilder pageBuilder;
  final StatHeader header;
  final InfoBox infoBox;
  final double height;

  const DetailScreen({
    Key? key,
    required this.title,
    required this.pageBuilder,
    required this.header,
    required this.infoBox,
    this.height = 200,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    PageController _pageController = usePageController();

    return Scaffold(
      appBar: AppTheme.appBar(title),
      body: ListView(
        padding: AppTheme.screenPadding,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [header, const ChartModeSelect()],
          ),
          AppTheme.separator,
          AnimatedSize(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
            child: SizedBox(
              height: height,
              child: PageView.builder(
                controller: _pageController,
                reverse: true,
                onPageChanged: (int page) {
                  ref.read(paginationProvider.notifier).state = Pagination(
                    page: page,
                    mode: ref.watch(paginationProvider).mode,
                  );
                },
                itemBuilder: pageBuilder,
              ),
            ),
          ),
          AppTheme.separator,
          infoBox,
        ],
      ),
    );
  }
}
