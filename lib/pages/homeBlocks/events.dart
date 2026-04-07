import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// A widget that embeds the UCSD Tritons website (News) in a WebView
/// with vertical scrolling enabled.
class EventsBlock extends StatefulWidget {
  const EventsBlock({Key? key}) : super(key: key);

  @override
  State<EventsBlock> createState() => _EventsBlockState();
}

class _EventsBlockState extends State<EventsBlock> {
  late final WebViewController _controller;
  bool _isLoading = true;
  final String newsUrl = 'https://calendar.ucsd.edu/';

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _isLoading = true),
          onPageFinished: (_) => setState(() => _isLoading = false),
          onWebResourceError: (error) {
            setState(() => _isLoading = false);
            if (kDebugMode) {
              print('Error loading page: ${error.description}');
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(newsUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // ClipRRect adds rounded corners.
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: WebViewWidget(
            controller: _controller,
            gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
              Factory<VerticalDragGestureRecognizer>(
                () => VerticalDragGestureRecognizer(),
              ),
            },
          ),
        ),
        if (_isLoading)
          const Center(child: CircularProgressIndicator()),
      ],
    );
  }
}

/// A full-screen page that displays the NewsBlock widget.
/// This provides the native scrolling behavior with an OS scrollbar.
class FullScreenEventsPage extends StatelessWidget {
  const FullScreenEventsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Triton Events', 
          style: TextStyle(
              decoration: TextDecoration.none, 
          ),
        ),
      ),
      body: const EventsBlock(),
    );
  }
}
