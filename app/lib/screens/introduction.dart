import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:scimovement/theme/theme.dart';
import 'package:scimovement/widgets/button.dart';
import 'package:go_router/go_router.dart';
import 'package:scimovement/gen_l10n/app_localizations.dart';
import 'package:scimovement/widgets/locale_select.dart';

class IntroductionHeader extends StatelessWidget {
  const IntroductionHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('RullaPå', style: AppTheme.headLine1.copyWith(height: 0.5)),
        Text(
          AppLocalizations.of(context)!.introductionScreenHeader,
          style:
              AppTheme.headLine3Light.copyWith(color: AppTheme.colors.primary),
        ),
        AppTheme.spacer4x,
        SvgPicture.asset('assets/svg/person.svg', width: 80),
        AppTheme.spacer2x,
        Padding(
          padding: AppTheme.elementPadding,
          child: Text(
            AppLocalizations.of(context)!.introductionWelcome,
            textAlign: TextAlign.center,
            style: AppTheme.paragraphMedium,
          ),
        ),
      ],
    );
  }
}

class IntroductionScreen extends StatelessWidget {
  const IntroductionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            ListView(
              padding: AppTheme.screenPadding,
              children: [
                const SizedBox(height: 64),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    IntroductionHeader(),
                    AppTheme.spacer2x,
                    _actions(context),
                    Image.asset('assets/images/ryggmarg_logo.png', width: 200),
                  ],
                ),
              ],
            ),
            Positioned(
              top: AppTheme.basePadding,
              right: AppTheme.basePadding,
              child: LocaleSelect(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actions(BuildContext context) {
    return Column(
      children: [
        Button(
          title: AppLocalizations.of(context)!.login,
          width: 180,
          onPressed: () => context.goNamed('login'),
        ),
        AppTheme.spacer2x,
        Button(
          title: AppLocalizations.of(context)!.register,
          width: 180,
          secondary: true,
          onPressed: () => context.goNamed('register'),
        ),
      ],
    );
  }
}
