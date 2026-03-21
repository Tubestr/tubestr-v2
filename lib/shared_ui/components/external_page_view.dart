import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

Future<void> openExternalPageWithFallback(
  BuildContext context, {
  required String title,
  required String url,
}) async {
  final uri = Uri.parse(url);
  for (final mode in const [
    LaunchMode.externalApplication,
    LaunchMode.platformDefault,
  ]) {
    try {
      final launched = await launchUrl(uri, mode: mode);
      if (launched) {
        return;
      }
    } catch (_) {
      // Some Android builds throw instead of returning false when no handler is available.
    }
  }
  if (!context.mounted) {
    return;
  }
  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => ExternalPageView(title: title, initialUrl: uri),
    ),
  );
}

class ExternalPageView extends StatefulWidget {
  const ExternalPageView({
    super.key,
    required this.title,
    required this.initialUrl,
  });

  final String title;
  final Uri initialUrl;

  @override
  State<ExternalPageView> createState() => _ExternalPageViewState();
}

class _ExternalPageViewState extends State<ExternalPageView> {
  late final WebViewController _controller;
  int _progress = 0;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (!mounted) {
              return;
            }
            setState(() {
              _isLoading = true;
              _errorMessage = null;
            });
          },
          onProgress: (progress) {
            if (!mounted) {
              return;
            }
            setState(() => _progress = progress);
          },
          onPageFinished: (_) {
            if (!mounted) {
              return;
            }
            setState(() {
              _isLoading = false;
              _progress = 100;
            });
          },
          onWebResourceError: (error) {
            if (!(error.isForMainFrame ?? true) || !mounted) {
              return;
            }
            setState(() {
              _isLoading = false;
              _errorMessage = error.description.isNotEmpty
                  ? error.description
                  : 'This page could not be loaded right now.';
            });
          },
        ),
      )
      ..loadRequest(widget.initialUrl);
  }

  Future<void> _reload() async {
    setState(() {
      _isLoading = true;
      _progress = 0;
      _errorMessage = null;
    });
    await _controller.loadRequest(widget.initialUrl);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            tooltip: 'Reload',
            onPressed: _reload,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          AnimatedOpacity(
            opacity: _isLoading ? 1 : 0,
            duration: const Duration(milliseconds: 180),
            child: LinearProgressIndicator(
              value: _progress == 0 || _progress == 100
                  ? null
                  : _progress / 100,
              minHeight: 2,
            ),
          ),
          Expanded(
            child: _errorMessage == null
                ? WebViewWidget(controller: _controller)
                : _ExternalPageErrorState(
                    title: widget.title,
                    url: widget.initialUrl.toString(),
                    message: _errorMessage!,
                    onRetry: _reload,
                  ),
          ),
        ],
      ),
    );
  }
}

class _ExternalPageErrorState extends StatelessWidget {
  const _ExternalPageErrorState({
    required this.title,
    required this.url,
    required this.message,
    required this.onRetry,
  });

  final String title;
  final String url;
  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.public_off_rounded,
                size: 44,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                '$title could not be loaded',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              SelectableText(
                url,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () async {
                  await onRetry();
                },
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
