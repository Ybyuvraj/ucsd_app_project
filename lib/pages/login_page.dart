import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../main.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  LoginPageState createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  static const iosClientId = '829956076330-0i20894pmbdrr8844k7g9ehds86rll34.apps.googleusercontent.com';
  static const webClientId = '829956076330-iuu3isoeb74m5acl22185s3m6n0ttsfh.apps.googleusercontent.com';

@override
Widget build(BuildContext context) {
  final screenHeight = MediaQuery.of(context).size.height;

  return Scaffold(
    backgroundColor: Colors.transparent,
    appBar: AppBar(
      title: const Text(' '),
      centerTitle: true,
      backgroundColor: const Color(0xFF1F1F1F),
    ),
    body: Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1F1F1F), Color.fromARGB(255, 7, 81, 134), Color.fromARGB(255, 15, 125, 203)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(bottom: screenHeight * 0.1),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Welcome to UCSD App',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: screenHeight * 0.03), 
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2C2C),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.7),
                      offset: const Offset(0, 6),
                      blurRadius: 10,
                    ),
                  ],
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    _buildTextField(
                      controller: _emailController,
                      labelText: 'Email',
                      icon: Icons.email_outlined,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _passwordController,
                      labelText: 'Password',
                      icon: Icons.lock_outline,
                      obscureText: true,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      child: ElevatedButton(
                        onPressed: _signIn,
                        style: _buttonStyle(),
                        child: const Text('Log In'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      child: ElevatedButton(
                        onPressed: _signUp,
                        style: _buttonStyle(),
                        child: const Text('Sign Up'),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      child: ElevatedButton.icon(
                        onPressed: _signInWithGoogle,
                        icon: Image.asset('lib/images/gLogo.png', height: 24),
                        label: const Text('Sign in with Google'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

  // ------------------------- TextField Helper -------------------------
  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    bool obscureText = false,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: const TextStyle(color: Colors.grey),
        prefixIcon: Icon(icon, color: Colors.grey),
        filled: true,
        fillColor: const Color(0xFF3A3A3A),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.transparent),
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.blue.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  // ------------------------- Button Style Helper -----------------------
  ButtonStyle _buttonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: const Color.fromARGB(255, 1, 110, 179), // or any dark color
      foregroundColor: const Color.fromARGB(255, 255, 255, 255),
      minimumSize: const Size(double.infinity, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      textStyle: const TextStyle(fontSize: 16),
    );
  }

  // ------------------------- Auth Methods -----------------------------
  Future<void> _signIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    // Client-side validation before making the request
    if (email.isEmpty || password.isEmpty) {
      _showMessage('Please enter both email and password.');
      return;
    }

    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      } else {
        _showMessage('Login failed. Please try again.');
      }
    } catch (e) {
      final errorMsg = e.toString();

      if (errorMsg.contains('Invalid login credentials')) {
        _showMessage('Incorrect email or password.');
      } else if (errorMsg.contains('validation_failed')) {
        _showMessage('Please check your input and try again.');
      } else {
        _showMessage('Login error: $e');
      }
    }
  }


  Future<void> _signUp() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if (email.isEmpty || password.isEmpty) {
      _showMessage('Please enter both email and password.');
      return;
    }
    if (password.length < 6) {
      _showMessage('Password is less than 6 words long. Please Try Again!');
      return;
    }
    try {
      await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
      );
      _showMessage('Sign up successful! Check your email to verify your account.');
    } catch (e) {
      _showMessage('Error: $e');
    }
  }

  Future<void> _signInWithGoogle() async {
    try {
      final googleSignIn = GoogleSignIn(
        clientId: iosClientId,
        serverClientId: webClientId,
      );
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        _showMessage('Google sign-in canceled.');
        return;
      }

      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (accessToken == null || idToken == null) {
        _showMessage('Missing Google token(s).');
        return;
      }

      final response = await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      if (response.user != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      } else {
        _showMessage('Google Sign-In failed');
      }
    } catch (e) {
      _showMessage('Google Sign-In error: $e');
    }
  }

  // ------------------------- Show Message -----------------------------
  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}
