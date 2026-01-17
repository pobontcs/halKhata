import 'package:flutter/material.dart';
// 1. Import your screens
import 'screens/landing.dart';
import 'screens/signup.dart';
import 'screens/dashboard.dart';
import 'screens/warehouse.dart';
import 'screens/sales_management.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Removes the little "Debug" sash
      title: 'Logistics App',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      
      // 2. THIS LINE controls what screen loads first
      initialRoute: '/', 
      
      // 3. Define the map of screens
      routes: {
        '/': (context) => const LandingPage()// '/' is always the start
        //'/signup': (context) => const SignupPage(),
        //'/dashboard': (context) => const DashboardPage(),
        ///'/warehouse': (context) => const WarehousePage(),
        ///'/sales': (context) => const SalesPage(),
      },
    );
  }
}