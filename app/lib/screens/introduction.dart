import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:scimovement/theme/theme.dart';
import 'package:scimovement/widgets/button.dart';
import 'package:go_router/go_router.dart';

class IntroductionScreen extends StatelessWidget {
  const IntroductionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: AppTheme.screenPadding,
          children: [
            const SizedBox(height: 64),
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _header(),
                AppTheme.spacer2x,
                _actions(context),
                Image.asset('assets/png/ryggmarg_logo.png', width: 200),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Column(
      children: [
        Text('RullaPå', style: AppTheme.headLine1.copyWith(height: 0.5)),
        Text(
          'spåra din rörelse',
          style:
              AppTheme.headLine3Light.copyWith(color: AppTheme.colors.primary),
        ),
        AppTheme.spacer4x,
        SvgPicture.asset('assets/svg/person.svg', width: 80),
        AppTheme.spacer2x,
        Padding(
          padding: AppTheme.elementPadding,
          child: Text(
            'Välkommen till appen RullaPå!\nVälj ett alternativ nedan för att komma igång.',
            textAlign: TextAlign.center,
            style: AppTheme.paragraphMedium,
          ),
        ),
      ],
    );
  }

  Widget _actions(BuildContext context) {
    return Column(
      children: [
        Button(
          title: 'Logga in',
          width: 180,
          onPressed: () => context.goNamed('login'),
        ),
        AppTheme.spacer2x,
        Button(
          title: 'Registrera',
          width: 180,
          secondary: true,
          onPressed: () => context.goNamed('register'),
        ),
      ],
    );
  }
}
