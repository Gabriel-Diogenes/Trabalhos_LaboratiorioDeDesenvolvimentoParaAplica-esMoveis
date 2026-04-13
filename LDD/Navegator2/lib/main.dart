import 'package:flutter/material.dart';
import 'pages/login_page.dart';
import 'pages/lista_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App Login/Cadastro',
      debugShowCheckedModeBanner: false,
      initialRoute: "/",
      onGenerateRoute: (settings) {
        if (settings.name == "/lista") {
          final nome = settings.arguments as String? ?? "Usuário";
          return MaterialPageRoute(
            builder: (context) => ListaPage(nome: nome),
          );
        }
        // Rota padrão: tela de login
        return MaterialPageRoute(
          builder: (context) => const LoginPage(),
        );
      },
    );
  }
}