import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Consulta de CEP',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _controllerCep = TextEditingController();
  String _resultado = 'Resultado';
  bool _carregando = false;

  Future<void> _recuperaCep() async {
    String cepDigitado = _controllerCep.text.replaceAll(RegExp(r'\D'), '');
    if (cepDigitado.length != 8) {
      setState(() => _resultado = 'CEP inválido. Digite 8 dígitos.');
      return;
    }

    setState(() => _carregando = true);

    var uri = Uri.parse("https://viacep.com.br/ws/$cepDigitado/json/");
    http.Response response = await http.get(uri);

    setState(() => _carregando = false);

    Map<String, dynamic> retorno = json.decode(response.body);

    if (retorno.containsKey('erro')) {
      setState(() => _resultado = 'CEP não encontrado.');
      return;
    }

    String logradouro = retorno["logradouro"] ?? '';
    String complemento = retorno["complemento"] ?? '';
    String bairro = retorno["bairro"] ?? '';
    String localidade = retorno["localidade"] ?? '';
    String uf = retorno["uf"] ?? '';

    setState(() {
      _resultado = "$logradouro $complemento\n$bairro\n$localidade - $uf";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Consumo de serviço web')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controllerCep,
              keyboardType: TextInputType.number,
              maxLength: 8,
              decoration: const InputDecoration(
                labelText: 'Digite o CEP (ex: 30360190)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _carregando ? null : _recuperaCep,
              child: _carregando
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Clique aqui'),
            ),
            const SizedBox(height: 20),
            Text(_resultado, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
