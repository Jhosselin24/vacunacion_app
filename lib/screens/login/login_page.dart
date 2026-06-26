import 'package:flutter/material.dart';
import 'forgot_password.dart';

class LoginPage extends StatelessWidget {

  LoginPage({super.key});

  final emailController = TextEditingController();

  final passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(

        title: const Text("Vacunación"),

      ),

      body: Padding(

        padding: const EdgeInsets.all(20),

        child: Column(

          children: [

            TextField(

              controller: emailController,

              decoration: const InputDecoration(

                labelText: "Correo",

              ),

            ),

            const SizedBox(height:20),

            TextField(

              controller: passwordController,

              obscureText: true,

              decoration: const InputDecoration(

                labelText: "Contraseña",

              ),

            ),

            const SizedBox(height:30),

            ElevatedButton(

              onPressed: () {},

              child: const Text("Ingresar"),

            ),
          TextButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ForgotPasswordPage(),
      ),
    );
  },
  child: const Text(
    "¿Olvidó su contraseña?",
  ),
),
          ],

        ),

      ),

    );

  }

}