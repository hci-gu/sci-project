import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scimovement/screens/journal/widgets/body_part_grid.dart';
import 'package:scimovement/screens/journal/widgets/journal_chart.dart';
import 'package:scimovement/theme/theme.dart';

class JournalScreen extends ConsumerWidget {
  const JournalScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hPadding = EdgeInsets.symmetric(
      horizontal: AppTheme.basePadding * 2,
    );

    return ListView(
      padding: EdgeInsets.symmetric(vertical: AppTheme.basePadding * 3),
      children: [
        _header(context),
        AppTheme.spacer2x,
        const JournalChart(),
        Padding(
          padding: hPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppTheme.separator,
              Text('Spåra smärta', style: AppTheme.headLine3),
              const BodyPartGrid(),
              AppTheme.separator,
              _seeAll(context),
              AppTheme.separator,
            ],
          ),
        ),
      ],
    );
  }

  Widget _header(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppTheme.basePadding * 2,
      ),
      child: Text('Smärta', style: AppTheme.headLine2),
    );
  }

  Widget _seeAll(BuildContext context) {
    return ListTile(
      dense: true,
      leading: const Icon(Icons.list),
      onTap: () => GoRouter.of(context).goNamed('journal-list'),
      title: Text(
        'Lista inlägg',
        style: AppTheme.labelLarge,
      ),
      subtitle: const Text('Se/editera gamla inlägg'),
      trailing: const Icon(Icons.arrow_forward_ios),
    );
  }
}
