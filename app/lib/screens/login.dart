import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
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
      appBar: AppTheme.appBar('RullaPå'),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 64.0, vertical: 24.0),
        child: ListView(
          shrinkWrap: true,
          children: [
            Image.asset('assets/png/ryggmarg_logo.png', width: 125),
            const Text(
              'Välkommen till\n RullaPå appen!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 8.0),
            const Text(
              'För att komma igång öppna länken nedan för att installera klockappen på din Fitbit.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16.0),
            Button(
              title: 'Starta Fitbit',
              width: 180,
              onPressed: () async {
                await _launchFitbitGallery();
              },
            ),
            const SizedBox(height: 16.0),
            const Text(
              'Om du redan gjort den här processen tidigare kan du logga in manuellt nedan med ditt användarID.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
              ),
            ),
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
