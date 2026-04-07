import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class MyCalendarPage extends StatefulWidget {
  const MyCalendarPage({Key? key}) : super(key: key);

  @override
  State<MyCalendarPage> createState() => _MyCalendarPageState();
}

class _MyCalendarPageState extends State<MyCalendarPage> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String _errorMessage = '';

  // Replace with your actual Flask app URL
  final String flaskAppUrl = 'https://ucsd-app-project.onrender.com';

  @override
  void initState() {
    super.initState();
    // Create controller with additional settings
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (url) {
          setState(() {
            _isLoading = true;
          });
        },
        onPageFinished: (url) {
          setState(() {
            _isLoading = false;
          });
        },
        onWebResourceError: (error) {
          setState(() {
            _errorMessage = error.description;
            _isLoading = false;
          });
        },
      ))
      ..loadRequest(Uri.parse('https://calendar.google.com/'));
  }

  Future<void> _openFlaskAppInBrowser() async {
    final uri = Uri.parse(flaskAppUrl);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $uri';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 45,
        title: const Text(
          "Google Calender",
          style: TextStyle(
            decoration: TextDecoration.none, 
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                // The WebView widget that should load Google Calendar
                WebViewWidget(controller: _controller),
                // Show a loader if the page is still loading.
                if (_isLoading)
                  const Center(child: CircularProgressIndicator()),
                // If there is an error, show it on-screen.
                if (_errorMessage.isNotEmpty)
                  Center(
                    child: Text(
                      'Error: $_errorMessage',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
              ],
            ),
          ),
          // Button to open the Flask schedule app in an external browser.
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: _openFlaskAppInBrowser,
              child: const Text('Open Schedule App'),
            ),
          ),
        ],
      ),
    );
  }
}
