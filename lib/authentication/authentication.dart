import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tailorapptask/services/supabase_stuff.dart';
import 'package:tailorapptask/pages/homepage.dart';

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
      await SB.signInWithGoogle();
      // signInWithOAuth will open web auth — on return the session is restored
      // Supabase auth state listener in main will navigate to HomePage
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sign-in failed: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) return const HomePage();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: _loading
            ? const CircularProgressIndicator()
            : FilledButton.icon(
          icon: const Icon(Icons.login),
          label: const Text('Sign in with Google'),
          onPressed: _signIn,
        ),
      ),
    );
  }
}
