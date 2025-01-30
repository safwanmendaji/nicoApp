import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:nicoapp/services/notication_services.dart';
import 'package:nicoapp/pages/loginPage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Initialize notification services
    NotificationServices().requestNotificationPermission();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const LoginPage(),
    );
  }
}
