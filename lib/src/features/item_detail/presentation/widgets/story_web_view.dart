import 'item_detail_text_body.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../../core/design_system/design_system.dart';

class StoryWebView extends StatefulWidget {
  const StoryWebView({
    super.key,
    required this.url,
    required this.onScroll,
    required this.onUserScroll,
    required this.onNavigationStarted,
  });

  final String url;
  final ValueChanged<double> onScroll;
  final ValueChanged<double> onUserScroll;
  final VoidCallback onNavigationStarted;

  @override
  State<StoryWebView> createState() => _StoryWebViewState();
}

class _StoryWebViewState extends State<StoryWebView> {
  WebViewController? _controller;
  bool _isLoading = true;
  bool _usesScrollBridge = false;
  bool _isUnsupported = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  @override
  void didUpdateWidget(covariant StoryWebView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) _load(widget.url);
  }

  @override
  Widget build(BuildContext context) {
    if (_isUnsupported) return UnsupportedWebViewBody(url: widget.url);
    final controller = _controller;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (controller != null)
          Listener(
            onPointerMove: (event) => _recordPan(event.delta),
            onPointerPanZoomUpdate: (event) => _recordPan(event.panDelta),
            onPointerSignal: (event) {
              if (event is PointerScrollEvent &&
                  event.scrollDelta.dy.abs() > event.scrollDelta.dx.abs()) {
                widget.onUserScroll(event.scrollDelta.dy);
              }
            },
            child: WebViewWidget(controller: controller),
          ),
        if (_isLoading && _errorMessage == null)
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: LinearProgressIndicator(
                minHeight: 2,
                semanticsLabel: 'Loading page',
              ),
            ),
          ),
        if (_errorMessage != null)
          ColoredBox(
            color: context.hpColors.paper,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 16,
                  children: [
                    Text(
                      'Unable to load this page.\n$_errorMessage',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: context.hpColors.inkMuted,
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => controller?.reload(),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _initializeController() async {
    try {
      final controller = WebViewController();
      await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
      await controller.setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (!mounted) return;
            widget.onNavigationStarted();
            setState(() {
              _errorMessage = null;
              _isLoading = true;
            });
          },
          onPageFinished: (_) {
            if (!mounted) return;
            setState(() => _isLoading = false);
            if (_usesScrollBridge) _installScrollBridge();
          },
          onWebResourceError: (error) {
            if (!mounted || error.isForMainFrame != true) return;
            widget.onNavigationStarted();
            setState(() {
              _isLoading = false;
              _errorMessage = error.description;
            });
          },
        ),
      );
      try {
        await controller.setOnScrollPositionChange((position) {
          _onScroll(position.y);
        });
      } on UnimplementedError {
        _usesScrollBridge = true;
      } on UnsupportedError {
        _usesScrollBridge = true;
      }
      if (_usesScrollBridge) {
        await controller.addJavaScriptChannel(
          'HeaderBridge',
          onMessageReceived: (message) {
            final offset = double.tryParse(message.message);
            if (offset != null) _onScroll(offset);
          },
        );
      }
      if (!mounted) return;
      setState(() => _controller = controller);
      _load(widget.url);
    } catch (_) {
      if (mounted) setState(() => _isUnsupported = true);
    }
  }

  void _onScroll(double offset) {
    if (!mounted || _errorMessage != null) return;
    widget.onScroll(offset);
  }

  void _recordPan(Offset delta) {
    if (delta.dy.abs() > delta.dx.abs()) widget.onUserScroll(-delta.dy);
  }

  void _load(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      setState(() => _errorMessage = 'Invalid URL');
      return;
    }
    _controller?.loadRequest(uri.hasScheme ? uri : Uri.parse('https://$url'));
  }

  Future<void> _installScrollBridge() async {
    try {
      await _controller?.runJavaScript("""
        (function() {
          if (window.__hackerPenHeaderBridgeInstalled) return;
          window.__hackerPenHeaderBridgeInstalled = true;
          var ticking = false;
          window.addEventListener('scroll', function() {
            if (ticking) return;
            ticking = true;
            window.requestAnimationFrame(function() {
              HeaderBridge.postMessage(String(Math.max(0, window.scrollY || 0)));
              ticking = false;
            });
          }, { passive: true });
        })();
      """);
    } catch (_) {
      if (mounted) widget.onNavigationStarted();
    }
  }
}
