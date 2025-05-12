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
  
  Future<void> addUserMovie(int idFilm, String idUser) async {
    try {
      await _supabase.client.from('usertable').insert({
        'id_film':idFilm,
        'id_user':idUser
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