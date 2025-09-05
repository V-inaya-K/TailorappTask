import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tailorapptask/pages/homepage.dart';
import 'package:tailorapptask/authentication/authkey.dart';
import 'package:tailorapptask/services/supabase_stuff.dart';
import 'package:tailorapptask/authentication/authentication.dart';
import 'package:tailorapptask/services/notification_feature.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // register top-level background handler BEFORE runApp
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // initialize supabase
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);

  // local notification & FCM handlers
  await NotificationService.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Todo Reminder',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.orange),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});
  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final SupabaseClient _client;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _client = Supabase.instance.client;
    // listen to auth state changes
    _client.auth.onAuthStateChange.listen((event) async {
      if (event.session != null) {
        // after sign in, upsert profile with token + metadata
        final user = _client.auth.currentUser!;
        final token = await NotificationService.getToken();
        await SB.upsertProfile(
          userId: user.id,
          name: user.userMetadata?['full_name'] ?? user.email,
          avatarUrl: user.userMetadata?['avatar_url'],
          fcmToken: token,
        );
      }
      if (mounted) setState(() {});
    });

    // initial bootstrap
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() => _loading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final session = _client.auth.currentSession;
    return session == null ? const LoginPage() : const HomePage();
  }
}
