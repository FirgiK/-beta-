import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:admin_gudang/database/database_helper.dart';
import 'package:admin_gudang/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper.database;

  runApp(const ProviderScope(child: AdminGudangApp()));
}

class AdminGudangApp extends StatelessWidget {
  const AdminGudangApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Admin Gudang - PT Paper Asturo Indonesia',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.light,
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          isDense: true,
        ),
        dataTableTheme: const DataTableThemeData(
          headingTextStyle: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
