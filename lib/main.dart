import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'frontend/splash_screen.dart';
//import 'frontend/login_screen.dart';
//import 'frontend/signup_screen.dart';
//import 'frontend/reset_password_screen1.dart';
//import 'frontend/reset_password_screen2.dart';
//import 'frontend/home_screen.dart';
//import 'frontend/add_devices_screen.dart';
//import 'frontend/alert_history_screen.dart';
//import 'frontend/profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); 
  await Firebase.initializeApp();             
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SafeZone',
      home: SplashScreen()
    );
  }
}