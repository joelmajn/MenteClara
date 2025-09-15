import 'package:flutter/material.dart';
import 'package:mente_clara/theme.dart';
import 'package:mente_clara/screens/home_screen.dart';
import 'package:mente_clara/services/notification_service.dart';
import 'package:mente_clara/services/data_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize notifications
  await NotificationService.initialize();
  
  // Initialize sample data
  await DataService.initializeSampleData();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mente Clara',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.system,
      home: const HomeScreen(),
    );
  }
}
