import 'package:flutter/material.dart';
import 'package:flutter_guitar/database/auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DrawerPage extends StatefulWidget {
  const DrawerPage({super.key});

  @override
  State<DrawerPage> createState() => _DrawerPageState();
}

class _DrawerPageState extends State<DrawerPage> {
  AuthService authService = AuthService();

  late final String user_id;
  dynamic userData;
  bool isLoading = true;

  @override
  void initState() {
    user_id = Supabase.instance.client.auth.currentUser!.id;
    getUserById();
    super.initState();
  }

  getUserById() async {
    try {
      final response = await Supabase.instance.client
          .from('users')
          .select('username, email')
          .eq('id', user_id);

      if (response != null && response.isNotEmpty) {
        setState(() {
          userData = response[0]; // Получаем первый элемент списка
          isLoading = false;
        });
      }
    } catch (e) {
      print(e);
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      shape: LinearBorder(),
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.fromARGB(255, 45, 5, 5),
              Color.fromARGB(255, 15, 15, 60),
            ],
          ),
        ),
        child: isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                DrawerHeader(
                  child: UserAccountsDrawerHeader(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    accountName: Text(userData['username'] ?? 'No username'),
                    accountEmail: Text(userData['email'] ?? 'No email'),
                    currentAccountPicture: Container(
                      alignment: Alignment.topCenter,
                      child: CircleAvatar(
                        maxRadius: 20,
                        minRadius: 10,
                        // backgroundImage: NetworkImage(userData['avatar']),
                      ),
                    ),
                    otherAccountsPictures: [
                      IconButton(
                        onPressed: () async {
                          await authService.logOut();
                          final prefs =
                              await SharedPreferences.getInstance();
                          await prefs.setBool('isLoggedIn', false);
                          Navigator.popAndPushNamed(context, '/auth');
                        },
                        icon: Icon(Icons.logout, color: Colors.white),
                      )
                    ],
                  ),
                ),
                ListTile(
                  iconColor: Colors.white,
                  textColor: Colors.white,
                  onTap: () {
                    Navigator.popAndPushNamed(context, '/tracks');
                  },
                  title: Text("Моя фильмотека"),
                  leading: Icon(Icons.music_note),
                ),
              ],
            ),
      ),
    );
  }
}