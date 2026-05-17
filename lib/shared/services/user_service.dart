import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';

class UserService {
  static final _client = Supabase.instance.client;

  static Future<UserProfile> fetchCurrentProfile() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('No authenticated user');

    final data = await _client
        .from('profiles')
        .select('''
          id,
          full_name,
          role,
          branch_id,
          color,
          branches (
            name,
            divisions (
              name
            )
          )
        ''')
        .eq('id', userId)
        .single();

    return UserProfile.fromMap(data);
  }

  static Future<void> signOut() async {
    await _client.auth.signOut();
  }
}