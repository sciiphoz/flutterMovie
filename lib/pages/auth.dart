import 'package:flutter/material.dart';
import 'package:flutter_guitar/database/auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthPage extends StatefulWidget 
{
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  AuthService authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color.fromARGB(255, 45, 20, 20), 
          Color.fromARGB(255, 35, 35, 60), ]
        )
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Image.asset('images/icon.png'),
              Text(
                "Вход",
                textScaler: TextScaler.linear(3),
                style: TextStyle(color: Colors.white),
              ),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.05,
              ),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                child: Column( 
                  children: [
                    TextField(
                      controller: emailController,
                      style: TextStyle(color: Colors.white),
                      cursorColor: Colors.white,
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.email, color: Colors.white),
                        labelText: 'Почта',
                      ),
                    ),
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.02,
                    ),
                    TextField(
                      controller: passwordController,
                      style: TextStyle(color: Colors.white),
                      cursorColor: Colors.white,
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.password, color: Colors.white),
                        labelText: 'Пароль',
                      ),
                    ),
                  ]
                )
              ),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.02,
              ),
              Container(
                width: MediaQuery.of(context).size.width * 0.8,
                alignment: Alignment.centerRight,
                child: InkWell(
                  child: Text("Забыли пароль?",),
                  onTap: (){ Navigator.popAndPushNamed(context, '/recovery'); },
                ),
              ),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.02,
              ),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.5,
                height: MediaQuery.of(context).size.height * 0.055,
                child: ElevatedButton(onPressed: () async { 
                  if (emailController.text.isEmpty || passwordController.text.isEmpty) {
                    ScaffoldMessenger.of(context,).showSnackBar(SnackBar(content: Text('Все поля должны быть заполнены.', style: TextStyle(color: Colors.white),), 
                    backgroundColor: Colors.blueGrey[700],));
                  } else {
                    var user = await authService.signIn(emailController.text, passwordController.text);
      
                    if (user != null) {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool("isLoggedIn", true);
      
                      ScaffoldMessenger.of(context,).showSnackBar(SnackBar(content: Text('Добро пожаловать, ${user.email!}.', style: TextStyle(color: Colors.white),), 
                      backgroundColor: Colors.blueGrey[700],));
      
                      Navigator.popAndPushNamed(context, '/'); 
                      print('asd');
                    } else {
                      ScaffoldMessenger.of(context,).showSnackBar(SnackBar(content: Text('Ошибка авторизации.', style: TextStyle(color: Colors.white),), 

                      backgroundColor: Colors.blueGrey[700],));
                    } 
                  }
                }, child: Text("Войти", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),),), 
              ),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.02,
              ),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.5,
                height: MediaQuery.of(context).size.height * 0.055,
                child: OutlinedButton(onPressed: () {
                  Navigator.popAndPushNamed(context, '/registration');
                }, child: Text("Зарегистрироваться", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),)),
              )
            ],
          ),
        ),
      ),
    );
  }
}