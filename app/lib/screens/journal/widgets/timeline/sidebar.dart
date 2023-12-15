import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scimovement/api/classes/journal/journal.dart';
import 'package:scimovement/models/journal/timeline.dart';
import 'package:scimovement/models/journal/timeline_chart.dart';
import 'package:scimovement/models/pagination.dart';
import 'package:scimovement/screens/journal/widgets/timeline/utils.dart';
import 'package:scimovement/theme/theme.dart';

class EventHandleItem extends ConsumerWidget {
  final TimelineType type;

  const EventHandleItem(this.type, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Container(
        // width: 160,
        height: type == TimelineType.movement
            ? eventHeight
            : heightForType(timelineDisplayType(type)),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 3,
              blurRadius: 3,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: EdgeInsets.all(AppTheme.basePadding),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                AutoSizeText(
                  type.displayString(context),
                  maxLines: 2,
                  style: AppTheme.labelSmall,
                  minFontSize: 10,
                ),
                _contentForType(context, ref),
              ],
            ),
            if (type == TimelineType.pain)
              Padding(
                padding: EdgeInsets.only(
                  bottom: AppTheme.basePadding,
                ),
                child: Container(
                  padding: EdgeInsets.only(left: AppTheme.halfPadding),
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(color: AppTheme.colors.lightGray),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [10, 7, 5, 3, 1]
                        .map((value) => Text(
                              value.toString(),
                              style: AppTheme.labelXTiny,
                            ))
                        .toList(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _contentForType(BuildContext context, WidgetRef ref) {
    switch (type) {
      case TimelineType.pain:
        return const LineChartSidebar();
      default:
    }
    return const SizedBox.shrink();
  }
}

class LineChartSidebar extends HookConsumerWidget {
  const LineChartSidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ValueNotifier<List<Category>> cachedResponse = useState([]);
    final fetch = ref.watch(timelineLineChartCategoriesForVisibleRange);

    useEffect(() {
      cachedResponse.value = fetch.value ?? [];

      return () {};
    }, [fetch]);

    return ref.watch(timelineLineChartCategoriesForVisibleRange).when(
          data: (bodyParts) => _content(bodyParts),
          error: (_, __) => const SizedBox.shrink(),
          loading: () => cachedResponse.value.isNotEmpty
              ? _content(cachedResponse.value)
              : const SizedBox.shrink(),
        );
  }

  Widget _content(List<Category> categories) {
    return Padding(
      padding: EdgeInsets.only(top: AppTheme.halfPadding),
      child: SizedBox(
        height: lineChartHeight - 40,
        width: 120,
        child: ListView.builder(
          itemCount: categories.length,
          itemBuilder: (context, index) => Padding(
            padding: const EdgeInsets.only(bottom: 4, left: 1),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 4,
                  height: 16,
                  decoration: BoxDecoration(
                    borderRadius: categories[index].isStepLine
                        ? BorderRadius.zero
                        : BorderRadius.circular(4),
                    border: Border.all(
                      color: AppTheme.colors.black,
                      width: 1,
                      strokeAlign: BorderSide.strokeAlignOutside,
                    ),
                    color: categories[index].color,
                  ),
                ),
                AppTheme.spacerHalf,
                categories[index].icon,
                AppTheme.spacer,
                Expanded(
                  child: AutoSizeText(
                    categories[index].title(context),
                    style: AppTheme.paragraphSmall,
                    maxLines: 1,
                    minFontSize: 8,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TimelineSidebar extends HookConsumerWidget {
  const TimelineSidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Pagination page = ref.watch(timelinePaginationProvider);
    ValueNotifier<List<TimelineType>> cachedResponse = useState([]);

    final fetch = ref.watch(timelineTypesProvider(page));

    useEffect(() {
      cachedResponse.value = fetch.value ?? [];

      return () {};
    }, [fetch]);

    return fetch.when(
      data: (data) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: data.map((e) => EventHandleItem(e)).toList(),
      ),
      error: (_, __) => const SizedBox.shrink(),
      loading: () => cachedResponse.value.isNotEmpty
          ? Column(
              children:
                  cachedResponse.value.map((e) => EventHandleItem(e)).toList(),
            )
          : const SizedBox.shrink(),
    );
  }
}
