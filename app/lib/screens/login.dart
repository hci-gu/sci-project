import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:scimovement/models/auth.dart';
import 'package:scimovement/theme/theme.dart';
import 'package:scimovement/widgets/button.dart';
import 'package:url_launcher/url_launcher.dart';

class LoginScreen extends HookWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    AuthModel auth = Provider.of<AuthModel>(context, listen: false);
    final _userIdController = useTextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'SCI Movement',
          style: AppTheme.appBarTextStyle,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 64.0, vertical: 24.0),
        child: Column(
          children: [
            // https://gallery.fitbit.com/details/1c0a1dfd-e31d-4ed7-bb74-b653337a9e8d
            Image.asset('assets/png/ryggmarg_logo.png', width: 125),
            const Text(
              'Welcome to the\n SCI Movement app!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 8.0),
            const Text(
              'To get started open the link below to install the watch app on your Fitbit.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16.0),
            Button(
              title: 'Launch Fitbit',
              width: 180,
              onPressed: () async {
                await _launchFitbitGallery();
              },
            ),
            const SizedBox(height: 16.0),
            const Text(
              'Or you can login manually if you already have done this process before.',
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
              title: 'Manual Login',
              icon: Icons.login,
              secondary: true,
              width: 180,
              onPressed: () async {
                bool success = await auth.login(_userIdController.text);
                if (success) context.goNamed('home');
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
