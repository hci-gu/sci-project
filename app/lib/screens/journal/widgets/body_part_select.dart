import 'package:flutter/material.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:scimovement/api/classes.dart';
import 'package:scimovement/screens/journal/widgets/body_part_icon.dart';
import 'package:scimovement/screens/settings/widgets/form_dropdown.dart';
import 'package:scimovement/theme/theme.dart';

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
                  title: 'Kroppsdel',
                  form: form,
                  hint: 'Välj kroppsdel',
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
                                    ),
                                  ),
                                  AppTheme.spacer,
                                  Text(bodyPartType.displayString())
                                ],
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ),
              if (showSideDropdown()) AppTheme.spacer2x,
              if (showSideDropdown())
                Flexible(
                  flex: 1,
                  child: FormDropdown(
                    formKey: 'side',
                    title: 'Sida',
                    form: form,
                    hint: 'Välj sida',
                    items: Side.values
                        .map((side) => DropdownMenuItem(
                              value: side,
                              child: Text(side.displayString()),
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
