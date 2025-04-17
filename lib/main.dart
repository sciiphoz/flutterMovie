import 'package:flutter/material.dart';
import 'package:flutter_guitar/pages/home.dart';
import 'package:flutter_guitar/pages/landing.dart';
import 'package:flutter_guitar/video/player.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_guitar/pages/auth.dart';
import 'package:flutter_guitar/pages/recovery.dart';
import 'package:flutter_guitar/pages/registration.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://mxpmkvurgancnbakuvxf.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im14cG1rdnVyZ2FuY25iYWt1dnhmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDQ2MjI1ODMsImV4cCI6MjA2MDE5ODU4M30.lr-8oG4PXNSw_RAJ_fEFhjyN14vLS31lipgQC2EO8QA',
  );

  runApp(MovieApp());
}

class MovieApp extends StatelessWidget {
  const MovieApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: true,
      theme: ThemeData(
        appBarTheme: AppBarTheme(
          iconTheme: IconThemeData(
            color: Colors.white
          )
        ),
        listTileTheme: ListTileThemeData(
          textColor: Colors.white,
          iconColor: Colors.white,
        ),
        scaffoldBackgroundColor: Colors.transparent,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ButtonStyle(
            backgroundColor: WidgetStatePropertyAll(Colors.white),
            foregroundColor: WidgetStatePropertyAll(Colors.blueGrey)
          )
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: ButtonStyle(
            foregroundColor: WidgetStatePropertyAll(Colors.white),
            side: WidgetStatePropertyAll(BorderSide(color: Colors.white)),
          )
        ),
        textTheme: TextTheme(
          bodyMedium: TextStyle(color: Colors.white)
        )
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => LandingPage(),
        '/auth': (context) => AuthPage(),
        '/registration': (context) => RegPage(),
        '/recovery': (context) => RecoveryPage(),
        '/home': (context) => HomePage(),
        '/player': (context) => VideoPage(),
      },
    );
  }
}