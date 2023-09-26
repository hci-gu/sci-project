import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scimovement/api/api.dart';
import 'package:scimovement/api/classes.dart';
import 'package:scimovement/models/bouts.dart';
import 'package:scimovement/models/energy.dart';
import 'package:scimovement/models/pagination.dart';
import 'package:scimovement/screens/exercise/add_exercise.dart';
import 'package:scimovement/theme/theme.dart';
import 'package:scimovement/widgets/editable_list_item.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ExcerciseScreen extends HookConsumerWidget {
  final bool startWithAdd;

  const ExcerciseScreen({
    Key? key,
    this.startWithAdd = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ValueNotifier<bool> isOpened = useState(startWithAdd);

    return Scaffold(
      appBar: AppTheme.appBar(AppLocalizations.of(context)!.exercise),
      floatingActionButton: Builder(builder: (context) {
        return AddExerciseButton(
          isOpened: isOpened.value,
          callback: () {
            isOpened.value = !isOpened.value;
          },
        );
      }),
      body: ref.watch(excerciseBoutsProvider(const Pagination())).when(
            data: (data) => _body(context, ref, data),
            error: (_, __) => Container(),
            loading: () => const Center(
              child: CircularProgressIndicator(),
            ),
          ),
    );
  }

  Widget _body(BuildContext context, WidgetRef ref, List<Bout> bouts) {
    return ListView.builder(
      itemCount: bouts.length,
      itemBuilder: (context, index) {
        return EditableListItem(
          id: bouts[index].time.toString(),
          title: bouts[index].activity.displayString(context),
          subtitle: bouts[index].displayDuration,
          onDismissed: () async {
            await Api().deleteBout(bouts[index].id);
            ref.invalidate(boutsProvider(const Pagination()));
            ref.invalidate(energyProvider(const Pagination()));
            ref.invalidate(excerciseBoutsProvider(const Pagination()));
          },
          onTap: () {},
        );
      },
    );
  }
}

class AddExerciseButton extends HookWidget {
  final bool isOpened;
  final Function callback;

  const AddExerciseButton({
    Key? key,
    required this.isOpened,
    required this.callback,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    useEffect(() {
      if (isOpened) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _openBottomSheet(context);
        });
      }
      return () {};
    });

    return FloatingActionButton(
      onPressed: () {
        if (isOpened) {
          Navigator.pop(context);
        } else {
          _openBottomSheet(context);
        }
        callback();
      },
      child: isOpened ? const Icon(Icons.close) : const Icon(Icons.add),
    );
  }

  void _openBottomSheet(BuildContext context) {
    showBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
      ),
      elevation: 4,
      clipBehavior: Clip.hardEdge,
      builder: (context) => AddExcercise(
        callback: () {
          Navigator.pop(context);
          callback();
        },
      ),
    );
  }
}
