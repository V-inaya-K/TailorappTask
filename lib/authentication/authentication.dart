import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tailorapptask/services/supabase_stuff.dart';
import 'package:tailorapptask/pages/homepage.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _loading = false;

  Future<void> _signIn() async {
    setState(() => _loading = true);

    try {
      await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? null : 'com.tailorapptask://login-callback',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign-in failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) return const HomePage();

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            'https://t4.ftcdn.net/jpg/02/67/40/21/240_F_267402109_jZvsqRQUvSxohAOmcUt549jlapqoRHM0.jpg',
            fit: BoxFit.cover,
          ),

          // Centered Title
          Center(
            child: Text(
              "Skeduler",
              style: GoogleFonts.satisfy(
                fontSize: 100,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: const [
                  Shadow(
                    offset: Offset(2, 2),
                    blurRadius: 6,
                    color: Colors.black54,
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 60),
              child: _loading
                  ? const CircularProgressIndicator()
                  : FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  minimumSize: const Size(280, 60),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: Icon(Icons.login, color: Colors.grey[700]),
                label: const Text(
                  'Sign in with Google',
                  style: TextStyle(color: Colors.black, fontSize: 20),
                ),
                onPressed: _signIn,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
