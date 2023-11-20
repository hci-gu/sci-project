import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scimovement/api/classes.dart';
import 'package:scimovement/api/classes/journal/journal.dart';
import 'package:scimovement/models/journal/timeline.dart';
import 'package:scimovement/models/pagination.dart';
import 'package:scimovement/screens/journal/widgets/body_part_icon.dart';
import 'package:scimovement/screens/journal/widgets/timeline/utils.dart';
import 'package:scimovement/theme/theme.dart';

class EventHandleItem extends ConsumerWidget {
  final JournalType type;

  const EventHandleItem(this.type, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Container(
        width: 160,
        height: heightForType(timelineDisplayTypeForJournalType(type)),
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
                SizedBox(
                  width: 120,
                  height: 24,
                  child: AutoSizeText(
                    type.displayString(context),
                    maxLines: 2,
                    style: AppTheme.labelMedium,
                    minFontSize: 10,
                  ),
                ),
                AppTheme.spacer,
                _contentForType(context, ref),
              ],
            ),
            if (type == JournalType.pain)
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
      case JournalType.pain:
        return const EventHandleBodyParts();
      default:
    }
    return const SizedBox.shrink();
  }
}

class EventHandleBodyParts extends HookConsumerWidget {
  const EventHandleBodyParts({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ValueNotifier<List<BodyPart>> cachedResponse = useState([]);
    final fetch = ref.watch(timelineBodyPartsForVisibleRange);

    useEffect(() {
      cachedResponse.value = fetch.value ?? [];

      return () {};
    }, [fetch]);

    return ref.watch(timelineBodyPartsForVisibleRange).when(
          data: (bodyParts) => _content(bodyParts),
          error: (_, __) => const SizedBox.shrink(),
          loading: () => cachedResponse.value.isNotEmpty
              ? _content(cachedResponse.value)
              : const SizedBox.shrink(),
        );
  }

  Widget _content(List<BodyPart> bodyParts) {
    return SizedBox(
      height: 88,
      width: 120,
      child: ListView.builder(
        itemCount: bodyParts.length,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(bottom: 4, left: 1),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 4,
                height: 16,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: AppTheme.colors.black,
                    width: 1,
                    strokeAlign: BorderSide.strokeAlignOutside,
                  ),
                  color: AppTheme.colors.bodyPartToColor(bodyParts[index]),
                ),
              ),
              AppTheme.spacerHalf,
              BodyPartIcon(
                bodyPart: bodyParts[index],
                size: 18,
              ),
              AppTheme.spacer,
              Expanded(
                child: AutoSizeText(
                  bodyParts[index].displayString(context),
                  style: AppTheme.paragraphSmall,
                  maxLines: 1,
                  minFontSize: 8,
                ),
              ),
            ],
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
    ValueNotifier<List<JournalType>> cachedResponse = useState([]);

    final fetch = ref.watch(timelineTypesProvider(page));

    useEffect(() {
      cachedResponse.value = fetch.value ?? [];

      return () {};
    }, [fetch]);

    return fetch.when(
      data: (data) => Column(
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
