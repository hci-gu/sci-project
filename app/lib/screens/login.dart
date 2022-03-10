import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:scimovement/models/auth.dart';
import 'package:scimovement/theme/theme.dart';

class LoginScreen extends HookWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    AuthModel auth = Provider.of<AuthModel>(context, listen: false);
    final _userIdController = useTextEditingController();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueGrey,
        title: const Text('SCI Movement'),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 64.0, vertical: 24.0),
        child: Column(
          children: [
            TextField(
              controller: _userIdController,
              decoration: const InputDecoration(
                labelText: 'User ID',
              ),
            ),
            const SizedBox(height: 16.0),
            TextButton.icon(
              style: AppTheme.buttonStyle,
              onPressed: () async {
                bool success = await auth.login(_userIdController.text);
                if (success) context.goNamed('home');
              },
              icon: Icon(Icons.login, color: AppTheme.colors.white),
              label: Text('Login', style: AppTheme.buttonTextStyle),
            )
          ],
        ),
      ),
    );
  }
}
