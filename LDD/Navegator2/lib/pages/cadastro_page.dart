import 'package:flutter/material.dart';

class CadastroPage extends StatefulWidget {
  const CadastroPage({super.key});

  @override
  State<CadastroPage> createState() => _CadastroPageState();
}

class _CadastroPageState extends State<CadastroPage> {
  double _tamanhoFonte = 16.0;
  bool _obscureText = true;
  bool _generoMasculino = false;
  bool _generoFeminino = false;
  bool _notificacaoEmail = false;
  bool _notificacaoTelefone = false;

  @override
  Widget build(BuildContext context) {
    TextStyle estilo = TextStyle(fontSize: _tamanhoFonte);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Create an account"),
        backgroundColor: Colors.blue,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            style: estilo,
            decoration: const InputDecoration(labelText: "E-mail"),
          ),

          TextField(
            obscureText: _obscureText,
            style: estilo,
            decoration: InputDecoration(
              labelText: "Senha",
              suffixIcon: IconButton(
                icon: Icon(_obscureText
                    ? Icons.visibility
                    : Icons.visibility_off),
                onPressed: () {
                  setState(() {
                    _obscureText = !_obscureText;
                  });
                },
              ),
            ),
          ),

          const SizedBox(height: 20),
          Text("Gênero:", style: estilo),

          CheckboxListTile(
            title: Text("Masculino", style: estilo),
            value: _generoMasculino,
            onChanged: (v) {
              setState(() => _generoMasculino = v!);
            },
          ),

          CheckboxListTile(
            title: Text("Feminino", style: estilo),
            value: _generoFeminino,
            onChanged: (v) {
              setState(() => _generoFeminino = v!);
            },
          ),

          const Divider(),

          SwitchListTile(
            title: Text("Notificação Email", style: estilo),
            value: _notificacaoEmail,
            onChanged: (v) {
              setState(() => _notificacaoEmail = v);
            },
          ),

          SwitchListTile(
            title: Text("Notificação Celular", style: estilo),
            value: _notificacaoTelefone,
            onChanged: (v) {
              setState(() => _notificacaoTelefone = v);
            },
          ),

          const Divider(),

          Slider(
            value: _tamanhoFonte,
            min: 10,
            max: 30,
            onChanged: (v) {
              setState(() => _tamanhoFonte = v);
            },
          ),

          ElevatedButton(
            onPressed: () {
              print("Cadastrado!");
              Navigator.pop(context); // 🔙 volta pro login
            },
            child: Text("Register", style: estilo),
          )
        ],
      ),
    );
  }
}