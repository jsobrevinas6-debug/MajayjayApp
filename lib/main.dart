import 'package:flutter/material.dart';
import 'package:flutter_application_2/admin/admin_dashboard.dart';
import 'package:flutter_application_2/student/student_dashboard.dart';
import 'package:flutter_application_2/mayor/mayor_dashboard.dart';
import 'package:flutter_application_2/login/login.dart';
import 'package:flutter_application_2/login/registration.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'https://lsafdwxgrstukbcfohbw.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxzYWZkd3hncnN0dWtiY2ZvaGJ3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQzNDU5MjAsImV4cCI6MjA3OTkyMTkyMH0.CoxUvzfyU7poptFoB6yDzX9oC0TPFMxhOX7v8xcci3Y',
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Majayjay Scholars',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF7FAFC),
        fontFamily: 'Inter',
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF667EEA),
          secondary: Color(0xFF764BA2),
          surface: Color(0xFFFFFFFF),
          error: Color(0xFFF56565),
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Color(0xFF2D3748)),
          headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: Color(0xFF2D3748)),
          bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: Color(0xFF2D3748)),
          bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: Color(0xFF4A5568)),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginPage(),
        '/admin/dashboard': (context) => const AdminDashboard(),
        '/mayor/dashboard': (context) => const MayorDashboardPage(),
        '/student/dashboard': (context) => const StudentDashboard(name: 'Student'),
        '/register': (context) => const RegistrationPage(),
      },
    );
  }
}
