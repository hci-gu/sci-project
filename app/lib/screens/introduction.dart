import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:scimovement/theme/theme.dart';
import 'package:scimovement/widgets/button.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';

class IntroductionScreen extends StatelessWidget {
  const IntroductionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: AppTheme.screenPadding,
        child: ListView(
          shrinkWrap: true,
          children: [
            const SizedBox(height: 100),
            _header(),
            const SizedBox(height: 16.0),
            Button(
              title: 'Starta Fitbit',
              width: 180,
              onPressed: () async {
                await _launchFitbitGallery();
              },
            ),
            const SizedBox(height: 16.0),
            Button(
              title: 'Logga in',
              width: 180,
              secondary: true,
              onPressed: () => context.goNamed('login'),
            ),
            const SizedBox(height: 32.0),
            Image.asset('assets/png/ryggmarg_logo.png', width: 200),
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
        const SizedBox(height: 32),
        SvgPicture.asset('assets/svg/person.svg', width: 100),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'För att komma igång öppna länken nedan för att installera klockappen på din Fitbit.',
            textAlign: TextAlign.center,
            style: AppTheme.paragraphMedium,
          ),
        ),
      ],
    );
  }

  Future<void> _launchFitbitGallery() async {
    if (!await launchUrl(
      Uri.https(
        'gallery.fitbit.com',
        'details/1c0a1dfd-e31d-4ed7-bb74-b653337a9e8d/openapp',
      ),
      mode: LaunchMode.externalApplication,
    )) {
      throw 'Could not launch';
    }
  }
}
