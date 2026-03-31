import 'package:flutter/material.dart';
import 'cadastro_page.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Login"),
        centerTitle: true,
        backgroundColor: Colors.blue,
      ),
      body: Center(
        child: SizedBox(
          width: 350,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const TextField(
                decoration: InputDecoration(labelText: 'E-mail'),
              ),
              const SizedBox(height: 20),

              const TextField(
                obscureText: true,
                decoration: InputDecoration(labelText: 'Senha'),
              ),
              const SizedBox(height: 30),

              ElevatedButton(
                onPressed: () {},
                child: const Text('Enter'),
              ),
              const SizedBox(height: 20),

              TextButton(
                onPressed: () {
                  // 🔗 Navega para cadastro
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CadastroPage(),
                    ),
                  );
                },
                child: const Text(
                  "Create an account",
                  style: TextStyle(color: Colors.blue),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}