import 'package:flutter/material.dart';
import 'core/supabase.dart';
import 'screens/login/login_page.dart';

Future<void> main() async {

  WidgetsFlutterBinding.ensureInitialized();

  await SupabaseConfig.init();

  runApp(const MyApp());

}

class MyApp extends StatelessWidget {

  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {

    return MaterialApp(

      debugShowCheckedModeBanner: false,

      home: LoginPage(),

    );

  }

}