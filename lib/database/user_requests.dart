import 'package:supabase_flutter/supabase_flutter.dart';


class UserRequests {
  final Supabase _supabase = Supabase.instance;

  Future<void> addUser(String username, String email, String password) async {
    try {
      await _supabase.client.from('users').insert({
        'email':email,
        'password':password,
        'username':username,
      });
    }
    catch (e) {
      print(e);
      return;
    }
  }
  
  Future<void> addUserMovie(int id_film, String id_user) async {
    try {
      await _supabase.client.from('usertable').insert({
        'id_film':id_film,
        'id_user':id_user
      });
    } catch (e) {
      print(e);
      return;
    }
  }

  Future<void> deleteUserTrack(int id) async {
    try {
      await _supabase.client.from('usertable').delete().eq('id', id);
    } catch (e) {
      print(e);
      return;
    }
  }

  Future<void> deleteUser() async {
    
  }
}