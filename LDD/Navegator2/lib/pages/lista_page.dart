import 'package:flutter/material.dart';

class ListaPage extends StatefulWidget {
  final String nome;

  const ListaPage({super.key, required this.nome});

  @override
  State<ListaPage> createState() => _ListaPageState();
}

class _ListaPageState extends State<ListaPage> {
  List _itens = [];

  void _carregarItens() {
    _itens = [];
    for (int i = 0; i < 20; i++) {
      Map<String, dynamic> item = Map();
      item["titulo"] = "Item ${i + 1}";
      item["descricao"] = "Descrição do item ${i + 1}";
      _itens.add(item);
    }
  }

  void _mostrarAlerta(BuildContext context, int indice) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Alerta"),
          content: Text("Você clicou no item $indice"),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                print("Selecionado sim");
                Navigator.pop(context);
              },
              child: const Text("Sim"),
            ),
            TextButton(
              onPressed: () {
                print("Selecionado não");
                Navigator.pop(context);
              },
              child: const Text("Não"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    _carregarItens();

    return Scaffold(
      appBar: AppBar(
        title: Text("Bem vindo(a), ${widget.nome}"),
        backgroundColor: Colors.blue,
      ),
      body: Container(
        padding: const EdgeInsets.all(20),
        child: ListView.builder(
          itemCount: _itens.length,
          itemBuilder: (context, indice) {
            return ListTile(
              onTap: () {
                _mostrarAlerta(context, indice);
              },
              onLongPress: () {
                print("Clique longo no item $indice");
              },
              title: Text(_itens[indice]["titulo"]),
              subtitle: Text(_itens[indice]["descricao"]),
            );
          },
        ),
      ),
    );
  }
}