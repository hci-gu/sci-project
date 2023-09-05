import 'package:flutter/material.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:scimovement/api/classes.dart';
import 'package:scimovement/screens/journal/widgets/body_part_icon.dart';
import 'package:scimovement/screens/settings/widgets/form_dropdown.dart';
import 'package:scimovement/theme/theme.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class BodyPartSelect extends StatelessWidget {
  final FormGroup form;

  const BodyPartSelect({Key? key, required this.form}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ReactiveFormConsumer(
      builder: ((context, formGroup, child) => Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              Flexible(
                flex: 2,
                child: FormDropdown(
                  formKey: 'bodyPartType',
                  title: AppLocalizations.of(context)!.bodyPart,
                  form: form,
                  hint:
                      '${AppLocalizations.of(context)!.select} ${AppLocalizations.of(context)!.bodyPart.toLowerCase()}',
                  items: BodyPartType.values
                      .map((bodyPartType) => DropdownMenuItem(
                            value: bodyPartType,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Row(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(4.0),
                                    child: BodyPartIcon(
                                      bodyPart: BodyPart(
                                        bodyPartType,
                                        form.value['side'] as Side,
                                      ),
                                      size: 48,
                                    ),
                                  ),
                                  AppTheme.spacer,
                                  Text(bodyPartType.displayString(context))
                                ],
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ),
              if (showSideDropdown()) AppTheme.spacer,
              if (showSideDropdown())
                Flexible(
                  flex: 1,
                  child: FormDropdown(
                    formKey: 'side',
                    title: AppLocalizations.of(context)!.side,
                    form: form,
                    hint:
                        '${AppLocalizations.of(context)!.select} ${AppLocalizations.of(context)!.side.toLowerCase()}',
                    items: Side.values
                        .map((side) => DropdownMenuItem(
                              value: side,
                              child: Text(
                                side.displayString(context),
                              ),
                            ))
                        .toList(),
                  ),
                ),
            ],
          )),
    );
  }

  bool showSideDropdown() {
    return form.value['bodyPartType'] != null &&
        form.value['bodyPartType'] != BodyPartType.neck &&
        form.value['bodyPartType'] != BodyPartType.back;
  }
}
