import 'package:flutter/material.dart';
import 'package:scimovement/theme/theme.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class EditableListItem extends StatelessWidget {
  final String id;
  final String title;
  final String subtitle;
  final Widget? icon;
  final Function onTap;
  final Function onDismissed;

  const EditableListItem({
    Key? key,
    required this.id,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.onDismissed,
    this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(id),
      onDismissed: (direction) {
        onDismissed();
      },
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) => _showDeleteDialog(context),
      background: Container(
        color: AppTheme.colors.error,
        child: const Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: EdgeInsets.only(right: 16),
            child: Icon(
              Icons.delete,
              color: Colors.white,
            ),
          ),
        ),
      ),
      child: ListTile(
        title: Text(title),
        leading: icon,
        subtitle: Text(subtitle),
        onTap: () => onTap(),
      ),
    );
  }

  Future<bool?> _showDeleteDialog(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.remove),
        content: Text(AppLocalizations.of(context)!.removeConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(AppLocalizations.of(context)!.remove),
          ),
        ],
      ),
    );
  }
}
