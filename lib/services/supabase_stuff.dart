import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tailorapptask/services/notification_feature.dart';

class SB {
  static final client = Supabase.instance.client;
  static Future<void> signInWithGoogle() async {
    await client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'io.supabase.flutter://login-callback/',
    );
  }

  static Future<void> upsertProfile({required String userId, String? name, String? avatarUrl, String? fcmToken}) async {
    await client.from('profiles').upsert({
      'id': userId,
      'name': name,
      'avatar_url': avatarUrl,
      'fcm_token': fcmToken,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
  }
  static Future<List<Map<String, dynamic>>> fetchTodos() async {
    try {
      final res = await client
          .from('todos')
          .select()
          .order('deadline', ascending: true);

      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      throw Exception("Error fetching todos: $e");
    }
  }

  static Future<void> insertTodo({required String userId, required String title, required DateTime deadline}) async {
    await client.from('todos').insert({
      'user_id': userId,
      'title': title,
      'deadline': deadline.toUtc().toIso8601String(),
      'notified': false,
    }).select();;
  }

  static Future<void> updateTodo({required String id, required String title, required DateTime deadline}) async {
    await client.from('todos').update({
      'title': title,
      'deadline': deadline.toUtc().toIso8601String(),
      'notified': false,
    }).eq('id', id).select();
  }

  static Future<void> deleteTodo(String id) async {
    await client.from('todos').delete().eq('id', id).select();
  }
}
