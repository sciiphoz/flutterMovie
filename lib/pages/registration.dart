import 'package:flutter/material.dart';
import 'package:flutter_guitar/database/auth.dart';
import 'package:flutter_guitar/database/user_requests.dart';
import 'package:flutter_guitar/video/player.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RegPage extends StatefulWidget 
{
  const RegPage({super.key});

  @override
  State<RegPage> createState() => _RegPageState();
}

class _RegPageState extends State<RegPage> {
  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController repeatController = TextEditingController();
  
  UserRequests userRequests = UserRequests();
  AuthService authService = AuthService();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.blue, Colors.blueGrey]
        )
      ),
      child: Scaffold(
        appBar: AppBar(
          actions: [
            ElevatedButton(onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => VideoPage()
                )
              );
            }, child: Text("s"))
          ],
        ),
        backgroundColor: Colors.transparent,        
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Image.asset('images/icon.png'),
              Text(
                "Регистрация",
                textScaler: TextScaler.linear(3),
                style: TextStyle(color: Colors.white),
              ),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                child: Column(
                  children: [
                    TextField(
                      style: TextStyle(color: Colors.white),
                      controller: nameController,
                      cursorColor: Colors.white,
                      decoration: InputDecoration(
                        labelText: 'Имя',
                      ),
                    ),
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.02,
                    ),
                    TextField(
                      style: TextStyle(color: Colors.white),
                      controller: emailController,
                      cursorColor: Colors.white,
                      decoration: InputDecoration(
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
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.02,
                    ),
                    TextField(
                      controller: repeatController,
                      style: TextStyle(color: Colors.white),
                      cursorColor: Colors.white,
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.password, color: Colors.white),
                        labelText: 'Подтвердите пароль',
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.02,
              ),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.5,
                child: ElevatedButton(onPressed: () async {
                  if (emailController.text.isEmpty || passwordController.text.isEmpty || repeatController.text.isEmpty || nameController.text.isEmpty) {
                    ScaffoldMessenger.of(context,).showSnackBar(SnackBar(content: Text('All field must be filled.', style: TextStyle(color: Colors.white),), 
                    backgroundColor: Colors.blueGrey[700],));
                  }
                  else {
                    if (passwordController.text == repeatController.text) {
                      var user = await authService.signUp(emailController.text, passwordController.text);
      
                      if (user != null) {
                        await userRequests.addUser(nameController.text, emailController.text, passwordController.text);
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setBool("isLoggedIn", true);
      
                        ScaffoldMessenger.of(context,).showSnackBar(SnackBar(content: Text('Welcome, ${user.email!}.', style: TextStyle(color: Colors.white),), 
                        backgroundColor: Colors.blueGrey[700],));
      
                        Navigator.popAndPushNamed(context, '/'); 
                      }
                    }
                    else { 
                      ScaffoldMessenger.of(context,).showSnackBar(SnackBar(content: Text('Passwords do not match.', style: TextStyle(color: Colors.white),), 
                      backgroundColor: Colors.blueGrey[700],)); 
                    }
                  }
                }, 
                child: Text("Создать аккаунт"),), 
              ),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.02,
              ),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.5,
                child: OutlinedButton(onPressed: (){
                  Navigator.popAndPushNamed(context, '/');
                }, child: Text("Войти")),
              )
            ],
          ),
        ),
      ),
    );
  }
}