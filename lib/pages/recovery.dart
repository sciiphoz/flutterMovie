import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_guitar/database/auth.dart';

class RecoveryPage extends StatelessWidget {
  const RecoveryPage({super.key});

  @override
  Widget build(BuildContext context) {
    TextEditingController emailController = TextEditingController();
    AuthService authService = AuthService(); 
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
        appBar: AppBar(
          title: Text("Восстановление пароля", style: TextStyle(color: Colors.white,)),
          leading: IconButton(onPressed: (){
            Navigator.popAndPushNamed(context, '/');
          }, icon: Icon(CupertinoIcons.back, color: Colors.white)),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.85,
                child: TextField(
                  style: TextStyle(color: Colors.white),
                  controller: emailController,
                  cursorColor: Colors.white,
                  decoration: InputDecoration(
                    prefixIcon: Icon(
                      Icons.email,
                      color: Colors.white,
                    ),
                    suffixIcon: IconButton(
                      onPressed: () async {
                        if (emailController.text.isEmpty) {
                          ScaffoldMessenger.of(context,).showSnackBar(SnackBar(content: Text('Поле почты должно быть заполнено.', style: TextStyle(color: Colors.white),), 
                          backgroundColor: Color.fromARGB(255, 30, 4, 40),));
                        } else {
                          await authService.recoveryPassword(emailController.text);
                          emailController.clear();
      
                          ScaffoldMessenger.of(context,).showSnackBar(SnackBar(content: Text('Письмо с инструкциями отправлено на почту $emailController.', style: TextStyle(color: Colors.white),), 
                          backgroundColor: Color.fromARGB(255, 30, 4, 40),));
                        }
                      },
                      icon: Icon(
                        Icons.send,
                        color: Colors.white,
                      ),
                    ),
                    labelText: 'Email',
                    labelStyle: TextStyle(color: Colors.white),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(color: Colors.white)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(0),
                      borderSide: BorderSide(color: Colors.white),
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.05,
              ),
              Text("Для восстановления доступа к своему аккаунту, пожалуйста введите свою почту.", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w500),)
            ],
          ),
        ),
      ),
    );
  }
}