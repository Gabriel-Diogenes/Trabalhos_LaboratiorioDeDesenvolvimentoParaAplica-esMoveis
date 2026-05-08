import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // Função para deslogar
  void _signOut() {
    FirebaseAuth.instance.signOut();
  }

  // Função para abrir o diálogo de edição de nome
  Future<void> _updateName(BuildContext context, String currentName) async {
    final controller = TextEditingController(text: currentName);
    
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar Perfil'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Seu nome'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx), 
            child: const Text('Cancelar')
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isEmpty) return;
              
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(FirebaseAuth.instance.currentUser!.uid)
                  .update({'name': controller.text.trim()});
              
              if (context.mounted) Navigator.pop(ctx);
            },
            child: const Text('Salvar'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Perfil'),
        actions: [
          IconButton(
            onPressed: _signOut, 
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
          )
        ],
      ),
      body: user == null 
          ? const Center(child: Text("Usuário não encontrado."))
          : StreamBuilder<DocumentSnapshot>(
              // Escuta as mudanças no documento do usuário em tempo real
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                // 1. Trata erro de conexão
                if (snapshot.hasError) {
                  return const Center(child: Text("Erro ao carregar dados."));
                }

                // 2. Mostra carregamento enquanto os dados não chegam
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // 3. Evita a TELA VERMELHA: verifica se o documento existe no Firestore
                // (Importante para quando o usuário acaba de criar a conta)
                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text("Configurando seu perfil no banco..."),
                      ],
                    ),
                  );
                }

                // 4. Se chegou aqui, os dados existem!
                var userData = snapshot.data!.data() as Map<String, dynamic>;
                String name = userData['name'] ?? 'Usuário';
                String role = userData['role'] ?? 'user';

                return Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircleAvatar(
                          radius: 50,
                          child: Icon(Icons.person, size: 50),
                        ),
                        const SizedBox(height: 20),
                        
                        // Alerta de Verificação de E-mail
                        if (!user.emailVerified)
                          Container(
                            padding: const EdgeInsets.all(10),
                            margin: const EdgeInsets.only(bottom: 20),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade100,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.warning, color: Colors.orange),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'E-mail não verificado. Verifique sua caixa de entrada!',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        Text(
                          'Olá, $name!',
                          style: const TextStyle(
                            fontSize: 24, 
                            fontWeight: FontWeight.bold
                          ),
                        ),
                        Text(
                          'E-mail: ${user.email}',
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 10),
                        Chip(
                          label: Text('Papel: $role'),
                          backgroundColor: Colors.blue.shade50,
                        ),
                        const SizedBox(height: 30),
                        
                        ElevatedButton.icon(
                          onPressed: () => _updateName(context, name),
                          icon: const Icon(Icons.edit),
                          label: const Text('Editar Nome no Firestore'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(200, 50),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}