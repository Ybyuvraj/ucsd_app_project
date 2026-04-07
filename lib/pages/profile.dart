import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'login_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({Key? key}) : super(key: key);

  // Handles sign-out logic
  Future<void> _signOut(BuildContext context) async {
    try {
      await Supabase.instance.client.auth.signOut();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  // Launches mail client to report issue
  Future<void> _sendEmail(BuildContext context) async {
    final Uri gmailUri = Uri.parse(
      "mailto:yuvraj.bhatia1130@gmail.com?subject=App%20Issue%20Report&body=Hi%20Yuvraj,%0A%0AI’m%20facing%20an%20issue%20with%20the%20app.%0ADetails:",
    );

    // Try opening Gmail directly (Android only)
    final androidGmailIntent = Uri(
      scheme: 'intent',
      path: '/send',
      query:
          'to=yuvraj.bhatia1130@gmail.com&subject=App%20Issue%20Report&body=Hi%20Yuvraj,%0A%0AI’m%20facing%20an%20issue%20with%20the%20app.%0ADetails:',
      fragment: 'Intent;package=com.google.android.gm;end;',
    );

    if (await canLaunchUrl(androidGmailIntent)) {
      await launchUrl(androidGmailIntent);
    } else if (await canLaunchUrl(gmailUri)) {
      await launchUrl(gmailUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not open Gmail or any mail app.")),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final createdAt = user?.createdAt != null
        ? DateTime.parse(user!.createdAt!).toLocal()
        : null;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: Scaffold(
        appBar: AppBar(
          title: const Text("Profile"),
          backgroundColor: Colors.black,
        ),
        backgroundColor: Colors.black,
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "Welcome back 👋",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Email:",
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.email ?? "Unknown",
                      style: const TextStyle(fontSize: 18, color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    if (createdAt != null) ...[
                      const Text(
                        "Member since:",
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${createdAt.toLocal().toString().split(' ').first}",
                        style: const TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ]
                  ],
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _signOut(context),
                icon: const Icon(Icons.logout),
                label: const Text("Log Out"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () => _sendEmail(context),
                icon: const Icon(Icons.mail_outline, color: Colors.white70),
                label: const Text(
                  "Report an Issue",
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
