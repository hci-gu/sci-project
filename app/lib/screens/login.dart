import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scimovement/models/auth.dart';
import 'package:scimovement/theme/theme.dart';
import 'package:scimovement/widgets/button.dart';
import 'package:url_launcher/url_launcher.dart';

class LoginScreen extends HookConsumerWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final _userIdController = useTextEditingController();

    return Scaffold(
      appBar: AppTheme.appBar('Logga in'),
      body: Padding(
        padding: AppTheme.screenPadding,
        child: ListView(
          shrinkWrap: true,
          children: [
            const SizedBox(height: 100),
            _header(),
            const SizedBox(height: 16.0),
            TextField(
              controller: _userIdController,
              decoration: const InputDecoration(
                labelText: 'User ID',
              ),
            ),
            const SizedBox(height: 16.0),
            Button(
              title: 'Logga in',
              icon: Icons.login,
              secondary: true,
              width: 180,
              onPressed: () async {
                ref.read(userProvider.notifier).login(_userIdController.text);
              },
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
