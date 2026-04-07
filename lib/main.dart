import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'pages/google_map_page.dart';
import 'pages/calender.dart';
import 'pages/login_page.dart';
import 'pages/profile.dart';
import 'pages/home.dart';
import 'pages/chatbot.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// ------------------------------------------------------------
/// MAIN ENTRY POINT
/// ------------------------------------------------------------
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://bwcyhcbectxzrxeyqiwi.supabase.co',
    anonKey:
        'sb_publishable_nm4yyS-9bC5LiRak-WeITw_Qi_2fmCW', // Replace with your Supabase Anon Key
  );

  runApp(const MyApp());
}

/// ------------------------------------------------------------
/// ROOT WIDGET
///   - Checks if user is logged in
///   - If logged in, show MainScreen
///   - If not logged in, show LoginPage
/// ------------------------------------------------------------
class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Track whether we have determined the initial auth state
  bool _isLoading = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    // Check if we already have a user logged in
    final user = Supabase.instance.client.auth.currentUser;
    setState(() {
      _isLoggedIn = (user != null);
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UCSD',
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.blue,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color.fromARGB(255, 2, 38, 69),
          titleTextStyle: TextStyle(
            color: Color.fromARGB(255, 255, 255, 255),
            fontSize: 20,
            fontWeight: FontWeight.bold,
            decoration: TextDecoration.underline,
          ),
          iconTheme: IconThemeData(color: Color(0xff03045E)),
          centerTitle: true,
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Colors.grey[900],
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.grey,
        ),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),
      debugShowCheckedModeBanner: false,
      // Show a loading screen while determining auth state
      home:
          _isLoading
              ? const Scaffold(body: Center(child: CircularProgressIndicator()))
              : (_isLoggedIn ? const MainScreen() : const LoginPage()),
    );
  }
}

/// ------------------------------------------------------------
/// LOGIN PAGE
///   - Handles email/password sign in and sign up
/// ------------------------------------------------------------

/// ------------------------------------------------------------
/// MAIN SCREEN
///   - Displays the bottom navigation bar with pages
///   - If user is not logged in, they will be redirected from elsewhere
/// ------------------------------------------------------------
class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomePage(),
    GoogleMapPage(),
    MyCalendarPage(),
    ChatbotPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          type: BottomNavigationBarType.fixed,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Maps'),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month),
              label: 'Calender',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.smart_toy),
              label: 'TritonAI',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}
