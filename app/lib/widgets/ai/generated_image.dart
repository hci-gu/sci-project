import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:scimovement/api/api.dart'; // adjust if your path differs
import 'package:scimovement/gen_l10n/app_localizations.dart';

class GeneratedImageView extends StatefulWidget {
  const GeneratedImageView({super.key, this.userId, this.title});

  final String? userId;
  final String? title;

  @override
  State<GeneratedImageView> createState() => _GeneratedImageViewState();
}

class _GeneratedImageViewState extends State<GeneratedImageView> {
  late Future<Uint8List?> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<Uint8List?> _load() {
    return Api().getGeneratedImage(userId: widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final title = widget.title ?? localizations.generatedImageTitle;

    return FutureBuilder<Uint8List?>(
      future: _future,
      builder: (context, snapshot) {
        // Loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _LoadingScaffold(title: title);
        }

        // Error or null result
        if (snapshot.hasError || snapshot.data == null) {
          return _ErrorScaffold(
            message: snapshot.hasError
                ? '${snapshot.error}'
                : localizations.noImageFromServer,
            onRetry: () => setState(() => _future = _load()),
          );
        }

        // Success
        final bytes = snapshot.data!;
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
            child: Image.memory(bytes, fit: BoxFit.fill),
          ),
        );
      },
    );
  }
}

class _LoadingScaffold extends StatelessWidget {
  const _LoadingScaffold({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 12),
          Text(AppLocalizations.of(context)!.generatingImage),
        ],
      ),
    );
  }
}

class _ErrorScaffold extends StatelessWidget {
  const _ErrorScaffold({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context)!.failedToLoadImage,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(AppLocalizations.of(context)!.tryAgain),
            ),
          ],
        ),
      ),
    );
  }
}
