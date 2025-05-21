import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_guitar/database/auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DrawerPage extends StatefulWidget {
  final bool isHomePage;
  const DrawerPage(
    {
      super.key,
      this.isHomePage = true
    }
  );

  @override
  State<DrawerPage> createState() => _DrawerPageState();
}

class _DrawerPageState extends State<DrawerPage> {
  AuthService authService = AuthService();

  late final String user_id;
  dynamic userData;

  bool isLoading = true;
  bool? _isHomePage;

  @override
  void initState() {
    user_id = Supabase.instance.client.auth.currentUser!.id;
    getUserById();
    _isHomePage = widget.isHomePage;
    super.initState();
  }

  getUserById() async {
    try {
      final response = await Supabase.instance.client
          .from('users')
          .select('username, email')
          .eq('id', user_id);

      if (response.isNotEmpty) {
        setState(() {
          userData = response[0];
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
        child: isLoading ? Center(child: CircularProgressIndicator()) : ListView(
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
                  ),
                ),
                otherAccountsPictures: [
                  IconButton(
                    onPressed: () async {
                      await authService.logOut();
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('isLoggedIn', false);
                      Navigator.popAndPushNamed(context, '/auth');
                    },
                    icon: Icon(Icons.logout, color: Colors.white),
                  )
                ],
              ),
            ),
            _isHomePage! ?
            ListTile(
              iconColor: Colors.white,
              textColor: Colors.white,
              onTap: () {
                Navigator.popAndPushNamed(context, '/myfilms');
              },
              title: Text("Моя фильмотека"),
              leading: Icon(CupertinoIcons.film),
            )
            :
            ListTile(
              iconColor: Colors.white,
              textColor: Colors.white,
              onTap: () {
                Navigator.popAndPushNamed(context, '/home');
              },
              title: Text("Главная"),
              leading: Icon(Icons.home),
            )
          ],
        ),
      ),
    );
  }
}