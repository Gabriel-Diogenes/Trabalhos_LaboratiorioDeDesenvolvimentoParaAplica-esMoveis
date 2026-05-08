import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

void main() {
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Home(),
    );
  }
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  // Método para recuperar ou abrir o banco de dados
  _recuperarBD() async {
    final caminho = await getDatabasesPath();
    final local = join(caminho, "bancodados_alunos.db");

    var retorno = await openDatabase(
      local,
      version: 1,
      onCreate: (db, dbVersaoRecente) {
        // Tabela 'alunos' com matricula como campo único e identificador principal
        String sql = "CREATE TABLE alunos ("
            "id INTEGER PRIMARY KEY AUTOINCREMENT, "
            "nome VARCHAR, "
            "idade INTEGER, "
            "matricula VARCHAR UNIQUE, "
            "curso VARCHAR)";
        db.execute(sql);
      },
    );

    print("Banco aberto: ${retorno.isOpen.toString()}");
    return retorno;
  }

  // Cadastra um novo aluno com nome, idade, matrícula e curso
  _salvarDados(BuildContext context, String nome, int idade, String matricula,
      String curso) async {
    if (matricula.isEmpty) {
      _mostrarDialogo(context, "A matrícula não pode estar vazia.");
      return;
    }
    if (curso.isEmpty) {
      _mostrarDialogo(context, "O nome do curso não pode estar vazio.");
      return;
    }

    Database db = await _recuperarBD();

    Map<String, dynamic> dadosAluno = {
      "nome": nome,
      "idade": idade,
      "matricula": matricula,
      "curso": curso,
    };

    try {
      int id = await db.insert("alunos", dadosAluno);
      print("Aluno salvo com ID: $id");
      _mostrarDialogo(context, "Aluno salvo com sucesso!\nMatrícula: $matricula");
    } catch (e) {
      _mostrarDialogo(
          context, "Erro ao salvar: matrícula '$matricula' já existe.");
    }
  }

  // Exibe um diálogo com título e mensagem
  _mostrarDialogo(BuildContext context, String mensagem) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Resultado"),
          content: Text(mensagem),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  // Lista todos os alunos cadastrados no console
  _listarAlunos() async {
    Database db = await _recuperarBD();
    String sql = "SELECT * FROM alunos";
    List alunos = await db.rawQuery(sql);

    for (var aluno in alunos) {
      print(
          "id: ${aluno['id']} | nome: ${aluno['nome']} | idade: ${aluno['idade']} | matricula: ${aluno['matricula']} | curso: ${aluno['curso']}");
    }
  }

  // Lista um aluno específico pela matrícula
  _listarUmAluno(BuildContext context, String matricula) async {
    if (matricula.isEmpty) {
      _mostrarDialogo(context, "Por favor, insira uma matrícula válida.");
      return;
    }

    Database db = await _recuperarBD();

    List alunos = await db.query(
      "alunos",
      columns: ["id", "nome", "idade", "matricula", "curso"],
      where: "matricula = ?",
      whereArgs: [matricula],
    );

    if (alunos.isNotEmpty) {
      var aluno = alunos.first;
      _mostrarDialogo(
        context,
        "ID: ${aluno['id']}\n"
        "Nome: ${aluno['nome']}\n"
        "Idade: ${aluno['idade']}\n"
        "Matrícula: ${aluno['matricula']}\n"
        "Curso: ${aluno['curso']}",
      );
    } else {
      _mostrarDialogo(
          context, "Aluno com matrícula '$matricula' não encontrado.");
    }
  }

  // Exclui um aluno pela matrícula
  _excluirAluno(BuildContext context, String matricula) async {
    if (matricula.isEmpty) {
      _mostrarDialogo(context, "Por favor, insira uma matrícula válida.");
      return;
    }

    Database db = await _recuperarBD();

    int retorno = await db.delete(
      "alunos",
      where: "matricula = ?",
      whereArgs: [matricula],
    );

    print("Registros excluídos: $retorno");

    if (retorno > 0) {
      _mostrarDialogo(
          context, "Aluno com matrícula '$matricula' excluído com sucesso.");
    } else {
      _mostrarDialogo(
          context, "Nenhum aluno encontrado com a matrícula '$matricula'.");
    }
  }

  // Atualiza dados de um aluno pela matrícula
  _atualizarAluno(BuildContext context, String matricula, String? nome,
      int? idade, String? curso) async {
    if (matricula.isEmpty) {
      _mostrarDialogo(context, "Por favor, insira uma matrícula válida.");
      return;
    }

    Database db = await _recuperarBD();

    Map<String, dynamic> dadosAluno = {};
    if (nome != null && nome.isNotEmpty) {
      dadosAluno["nome"] = nome;
    }
    if (idade != null) {
      dadosAluno["idade"] = idade;
    }
    if (curso != null && curso.isNotEmpty) {
      dadosAluno["curso"] = curso;
    }

    if (dadosAluno.isNotEmpty) {
      int retorno = await db.update(
        "alunos",
        dadosAluno,
        where: "matricula = ?",
        whereArgs: [matricula],
      );

      print("Registros atualizados: $retorno");

      if (retorno > 0) {
        _mostrarDialogo(
            context, "Aluno com matrícula '$matricula' atualizado com sucesso.");
      } else {
        _mostrarDialogo(
            context, "Nenhum aluno encontrado com a matrícula '$matricula'.");
      }
    } else {
      _mostrarDialogo(context, "Nenhuma informação para atualizar.");
    }
  }

  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _idadeController = TextEditingController();
  final TextEditingController _matriculaController = TextEditingController();
  final TextEditingController _cursoController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Cadastro de Alunos"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Seção: Dados do aluno ──
            const Text(
              "Dados do Aluno",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: 320,
              child: TextField(
                controller: _nomeController,
                decoration: const InputDecoration(
                  labelText: "Nome",
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: 320,
              child: TextField(
                controller: _idadeController,
                decoration: const InputDecoration(
                  labelText: "Idade",
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: 320,
              child: TextField(
                controller: _matriculaController,
                decoration: const InputDecoration(
                  labelText: "Matrícula",
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: 320,
              child: TextField(
                controller: _cursoController,
                decoration: const InputDecoration(
                  labelText: "Nome do Curso",
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Botão Salvar ──
            ElevatedButton.icon(
              onPressed: () {
                _salvarDados(
                  context,
                  _nomeController.text,
                  int.tryParse(_idadeController.text) ?? 0,
                  _matriculaController.text,
                  _cursoController.text,
                );
              },
              icon: const Icon(Icons.save),
              label: const Text("Salvar Aluno"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                minimumSize: const Size(200, 45),
              ),
            ),
            const SizedBox(height: 10),

            // ── Botão Listar Todos ──
            ElevatedButton.icon(
              onPressed: _listarAlunos,
              icon: const Icon(Icons.list),
              label: const Text("Listar todos (console)"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                minimumSize: const Size(200, 45),
              ),
            ),

            const Divider(height: 32),

            // ── Seção: Operações por matrícula ──
            const Text(
              "Operações por Matrícula",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              "Preencha a matrícula acima e use os botões abaixo.",
              style: TextStyle(fontSize: 13, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // ── Botão Listar Um ──
            ElevatedButton.icon(
              onPressed: () {
                _listarUmAluno(context, _matriculaController.text);
              },
              icon: const Icon(Icons.search),
              label: const Text("Listar Aluno"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                minimumSize: const Size(200, 45),
              ),
            ),
            const SizedBox(height: 10),

            // ── Botão Excluir ──
            ElevatedButton.icon(
              onPressed: () {
                _excluirAluno(context, _matriculaController.text);
              },
              icon: const Icon(Icons.delete),
              label: const Text("Excluir Aluno"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                minimumSize: const Size(200, 45),
              ),
            ),
            const SizedBox(height: 10),

            // ── Botão Atualizar ──
            ElevatedButton.icon(
              onPressed: () {
                String? nome = _nomeController.text.isNotEmpty
                    ? _nomeController.text
                    : null;
                int? idade = int.tryParse(_idadeController.text);
                String? curso = _cursoController.text.isNotEmpty
                    ? _cursoController.text
                    : null;
                _atualizarAluno(
                    context, _matriculaController.text, nome, idade, curso);
              },
              icon: const Icon(Icons.edit),
              label: const Text("Atualizar Aluno"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                minimumSize: const Size(200, 45),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
