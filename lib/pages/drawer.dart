import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_guitar/database/auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DrawerPage extends StatefulWidget {
  final bool isHomePage;
  const DrawerPage({
    super.key,
    this.isHomePage = true
  });

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

  Future<void> _showLogoutConfirmation(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // Пользователь должен нажать кнопку для закрытия
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color.fromARGB(255, 30, 30, 50),
          title: Text(
            'Подтверждение выхода',
            style: TextStyle(color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                  'Вы уверены, что хотите выйти из аккаунта?',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Отмена',
                style: TextStyle(color: Colors.grey),
              ),
              onPressed: () {
                Navigator.of(context).pop(); // Закрываем диалог
              },
            ),
            TextButton(
              child: Text(
                'Выйти',
                style: TextStyle(color: Colors.redAccent),
              ),
              onPressed: () async {
                Navigator.of(context).pop(); // Закрываем диалог
                await _performLogout(context);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _performLogout(BuildContext context) async {
    try {
      await authService.logOut();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', false);
      
      // Закрываем drawer перед переходом
      Navigator.pop(context);
      Navigator.pushReplacementNamed(context, '/auth');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка при выходе: ${e.toString()}'),
          backgroundColor: Colors.red,
        )
      );
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
          : Column(
            children: [
              // Верхняя часть с информацией о пользователе
              DrawerHeader(
                child: UserAccountsDrawerHeader(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  accountName: Text(userData['username'] ?? 'Без имени'),
                  accountEmail: Text(userData['email'] ?? 'Email не указан'),
                  currentAccountPicture: Container(
                    alignment: Alignment.topCenter,
                    child: CircleAvatar(
                      backgroundColor: Color.fromARGB(255, 80, 10, 20),
                      child: Text(
                        userData['username'] != null && userData['username'].isNotEmpty
                          ? userData['username'][0].toUpperCase()
                          : '?',
                        style: TextStyle(fontSize: 20, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
              
              // Навигационные элементы
              _isHomePage!
                ? ListTile(
                    iconColor: Colors.white,
                    textColor: Colors.white,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/myfilms');
                    },
                    title: Text("Моя фильмотека"),
                    leading: Icon(CupertinoIcons.film),
                  )
                : ListTile(
                    iconColor: Colors.white,
                    textColor: Colors.white,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/home');
                    },
                    title: Text("Главная"),
                    leading: Icon(Icons.home),
                  ),
              
              // Пустое пространство для заполнения
              Expanded(child: SizedBox()),
              
              // Кнопка выхода внизу
              Padding(
                padding: const EdgeInsets.only(bottom: 20.0, left: 16, right: 16),
                child: ListTile(
                  iconColor: Colors.redAccent,
                  textColor: Colors.redAccent,
                  onTap: () => _showLogoutConfirmation(context),
                  title: Text(
                    "Выйти",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  leading: Icon(Icons.logout),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: Colors.redAccent.withOpacity(0.5)),
                  ),
                ),
              ),
            ],
          ),
      ),
    );
  }
}