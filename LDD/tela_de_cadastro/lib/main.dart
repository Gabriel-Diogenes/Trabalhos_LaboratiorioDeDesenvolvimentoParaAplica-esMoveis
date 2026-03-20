import 'package:flutter/material.dart';

void main() {
  runApp(MaterialApp(
    home: TelaCadastro(),
    debugShowCheckedModeBanner: false,
  ));
}

class TelaCadastro extends StatefulWidget {
  @override
  _TelaCadastroState createState() => _TelaCadastroState();
}

class _TelaCadastroState extends State<TelaCadastro> {
  double _tamanhoFonte = 16.0; 
  bool _obscureText = true;
  bool _generoMasculino = false;
  bool _generoFeminino = false;
  bool _notificacaoEmail = false;
  bool _notificacaoTelefone = false;

  @override
  Widget build(BuildContext context) {
    TextStyle estiloDinamico = TextStyle(fontSize: _tamanhoFonte);

    return Scaffold(
      appBar: AppBar(
        title: Text("Tela de Cadastro", style: estiloDinamico),
        backgroundColor: Colors.blueAccent,
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          TextField(
            keyboardType: TextInputType.name,
            maxLength: 50, 
            style: estiloDinamico,
            decoration: InputDecoration(labelText: "Nome"),
          ),
          TextField(
            keyboardType: TextInputType.datetime,
            style: estiloDinamico,
            decoration: InputDecoration(labelText: "Data de Nascimento (DD/MM/AAAA)"),
          ),
          TextField(
            keyboardType: TextInputType.phone,
            maxLength: 15,
            style: estiloDinamico,
            decoration: InputDecoration(labelText: "Telefone"),
          ),
          TextField(
            keyboardType: TextInputType.emailAddress, 
            style: estiloDinamico,
            decoration: InputDecoration(labelText: "E-mail"),
          ),
          
          TextField(
            keyboardType: TextInputType.text,
            obscureText: _obscureText, 
            maxLength: 20,
            style: estiloDinamico,
            decoration: InputDecoration(
              labelText: "Senha",
              suffixIcon: IconButton(
                icon: Icon(_obscureText ? Icons.visibility : Icons.visibility_off),
                onPressed: () {
                  setState(() { _obscureText = !_obscureText; });
                },
              ),
            ),
          ),

          SizedBox(height: 20),
          Text("Gênero:", style: estiloDinamico),
        
          CheckboxListTile(
            title: Text("Masculino", style: estiloDinamico),
            value: _generoMasculino,
            onChanged: (bool? valor) {
              setState(() { _generoMasculino = valor!; });
            },
          ),
          CheckboxListTile(
            title: Text("Feminino", style: estiloDinamico),
            value: _generoFeminino,
            onChanged: (bool? valor) {
              setState(() { _generoFeminino = valor!; });
            },
          ),

          Divider(),
          Text("Notificações:", style: estiloDinamico),
          
          SwitchListTile(
            title: Text("E-mail", style: estiloDinamico),
            value: _notificacaoEmail,
            onChanged: (bool valor) {
              setState(() { _notificacaoEmail = valor; });
            },
          ),
          SwitchListTile(
            title: Text("Telefone", style: estiloDinamico),
            value: _notificacaoTelefone,
            onChanged: (bool valor) {
              setState(() { _notificacaoTelefone = valor; });
            },
          ),

          Divider(),
          Text("Ajustar Tamanho da Fonte:", style: estiloDinamico),
          Slider(
            value: _tamanhoFonte,
            min: 10,
            max: 30,
            divisions: 10, 
            label: "Tamanho: ${_tamanhoFonte.toInt()}", 
            onChanged: (double novoValor) {
              setState(() {
                _tamanhoFonte = novoValor;
              });
            },
          ),

          SizedBox(height: 20),
          ElevatedButton(
            child: Text("Cadastrar", style: estiloDinamico),
            onPressed: () {
              print("Cadastro realizado!");
            },
          ),
        ],
      ),
    );
  }
}