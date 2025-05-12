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

  final String user_id = Supabase.instance.client.auth.currentUser!.id.toString();
  dynamic docs;

  @override
  void initState() {
    getUserById();
    super.initState();
  }

  Future<void> getUserById() async {
    try {
      final userGet = await Supabase.instance.client.from('users').select('username, email').eq('id', user_id);

      setState(() {
        docs = userGet;
      });
    }
    catch (e) { print(e); }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          colors: [Color.fromARGB(255, 45, 5, 5), 
          Color.fromARGB(255, 15, 15, 60), ]
          )
        ),
        child: ListView(
          children: [
            DrawerHeader(
              child: UserAccountsDrawerHeader(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20)
                ),
                accountName: Text(docs['username']), 
                accountEmail: Text(docs['email']),
                currentAccountPicture: Container(
                  alignment: Alignment.topCenter,
                  child: CircleAvatar(
                    maxRadius: 20,
                    minRadius: 10,
                    // backgroundImage: NetworkImage(docs['avatar']),
                  ),
                ),
                otherAccountsPictures: [
                  IconButton(onPressed: () async {
                    await authService.logOut();
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('isLoggedIn', false);
                    Navigator.popAndPushNamed(context, '/auth');
                  }, icon: Icon(Icons.logout, color: Colors.white,))
                ],
              )
            ),
            ListTile(
              iconColor: Colors.white,
              textColor: Colors.white,
              onTap: () {
                Navigator.popAndPushNamed(context, '/tracks');
              },
              title: Text("Моя "),
              leading: Icon(Icons.music_note),
            ),
          ],
        ),
      ),
    );
  }
}