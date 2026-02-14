import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // <--- 1. IMPORT FIREBASE

// Import your screens
import 'screens/landing.dart';
import 'screens/signup.dart';
import 'screens/dashboard.dart';
import 'screens/warehouse.dart';
import 'screens/sales_management.dart';

// 2. CHANGE TO ASYNC MAIN
void main() async {
  // 3. REQUIRED FOR FIREBASE
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
      title: 'Logistics App',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange), // Changed to Orange to match your app
      ),

      initialRoute: '/',

      // 4. DEFINE ROUTES (Uncommented and Fixed)
      routes: {
        '/': (context) => const LandingPage(),
        //'/signup': (context) => const SignupPage(),

        // We pass a default username here so the route doesn't crash
        //'/dashboard': (context) => const DashboardPage(username: "Admin"),

       // '/warehouse': (context) => const WareHouse(),
        // '/sales': (context) => const SalesPage(), // Keep commented until you create this file
      },
    );
  }
}