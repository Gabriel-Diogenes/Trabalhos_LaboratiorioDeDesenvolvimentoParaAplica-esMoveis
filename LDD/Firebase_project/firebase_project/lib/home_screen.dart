import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';

import 'storage_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _emailVerified =
      FirebaseAuth.instance.currentUser?.emailVerified ?? false;

  Future<void> _signOut() async {
    await GoogleSignIn().signOut();
    await FirebaseAuth.instance.signOut();
  }

  Future<void> _updateName(
    BuildContext context,
    String currentName,
  ) async {
    final controller = TextEditingController(text: currentName);

    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar Nome'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Seu nome',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                if (controller.text.trim().isEmpty) {
                  throw Exception('O nome não pode estar vazio.');
                }

                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(FirebaseAuth.instance.currentUser!.uid)
                    .update({
                  'name': controller.text.trim(),
                });

                if (context.mounted) {
                  Navigator.pop(ctx);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Nome atualizado com sucesso!'),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erro ao atualizar nome: $e'),
                    ),
                  );
                }
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndUploadPhoto(BuildContext context) async {
    try {
      final picker = ImagePicker();

      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 75,
      );

      if (pickedFile == null) return;

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Enviando foto...'),
          ),
        );
      }

      final url = await StorageService().uploadProfilePicture(
        File(pickedFile.path),
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              url != null
                  ? 'Foto atualizada com sucesso!'
                  : 'Erro ao enviar foto.',
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao selecionar imagem: $e'),
          ),
        );
      }
    }
  }

  Future<void> _sendVerificationEmail(
    BuildContext context,
  ) async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw Exception('Usuário não encontrado.');
      }

      await user.sendEmailVerification();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Link de verificação enviado com sucesso!',
            ),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Erro ao enviar e-mail de verificação.';

      if (e.code == 'too-many-requests') {
        message =
            'Muitas tentativas realizadas. Aguarde alguns minutos.';
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro inesperado: $e'),
          ),
        );
      }
    }
  }

  Future<void> _checkEmailVerification(
    BuildContext context,
  ) async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw Exception('Usuário não encontrado.');
      }

      await user.reload();

      final refreshedUser = FirebaseAuth.instance.currentUser;

      if (refreshedUser != null && refreshedUser.emailVerified) {
        setState(() {
          _emailVerified = true;
        });

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'E-mail verificado com sucesso!',
              ),
            ),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Seu e-mail ainda não foi verificado.',
              ),
            ),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erro Firebase: ${e.message}',
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro inesperado: $e'),
          ),
        );
      }
    }
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
          ),
        ],
      ),
      body: user == null
          ? const Center(
              child: Text('Usuário não encontrado.'),
            )
          : StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Text('Erro ao carregar dados.'),
                  );
                }

                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Configurando seu perfil...'),
                      ],
                    ),
                  );
                }

                final userData =
                    snapshot.data!.data() as Map<String, dynamic>;

                final String name =
                    userData['name'] ?? 'Usuário';

                final String role =
                    userData['role'] ?? 'user';

                final String photo =
                    userData['photo'] ?? '';

                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () =>
                              _pickAndUploadPhoto(context),
                          child: Stack(
                            alignment:
                                Alignment.bottomRight,
                            children: [
                              CircleAvatar(
                                radius: 50,
                                backgroundImage:
                                    photo.isNotEmpty
                                        ? NetworkImage(photo)
                                        : null,
                                child: photo.isEmpty
                                    ? const Icon(
                                        Icons.person,
                                        size: 50,
                                      )
                                    : null,
                              ),
                              CircleAvatar(
                                radius: 16,
                                backgroundColor:
                                    Colors.blue,
                                child: const Icon(
                                  Icons.camera_alt,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 8),

                        const Text(
                          'Toque na foto para alterar',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),

                        const SizedBox(height: 16),

                        if (!_emailVerified)
                          Container(
                            padding:
                                const EdgeInsets.all(12),
                            margin:
                                const EdgeInsets.only(
                              bottom: 20,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  Colors.amber.shade100,
                              borderRadius:
                                  BorderRadius.circular(
                                10,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(
                                      Icons.warning,
                                      color:
                                          Colors.orange,
                                    ),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'E-mail não verificado. Verifique sua caixa de entrada!',
                                        style:
                                            TextStyle(
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 8),

                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment
                                          .end,
                                  children: [
                                    TextButton(
                                      onPressed: () =>
                                          _sendVerificationEmail(
                                        context,
                                      ),
                                      child: const Text(
                                        'Reenviar link',
                                      ),
                                    ),
                                    const SizedBox(
                                        width: 8),
                                    ElevatedButton(
                                      onPressed: () =>
                                          _checkEmailVerification(
                                        context,
                                      ),
                                      child: const Text(
                                        'Já verifiquei',
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                        if (_emailVerified)
                          Container(
                            width: double.infinity,
                            padding:
                                const EdgeInsets.all(12),
                            margin:
                                const EdgeInsets.only(
                              bottom: 20,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  Colors.green.shade100,
                              borderRadius:
                                  BorderRadius.circular(
                                10,
                              ),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'E-mail verificado com sucesso!',
                                    style: TextStyle(
                                      color:
                                          Colors.green,
                                      fontWeight:
                                          FontWeight
                                              .bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        Text(
                          'Olá, $name!',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),

                        Text(
                          user.email ?? '',
                          style: const TextStyle(
                            color: Colors.grey,
                          ),
                        ),

                        const SizedBox(height: 10),

                        Chip(
                          label: Text('Papel: $role'),
                          backgroundColor:
                              Colors.blue.shade50,
                        ),

                        const SizedBox(height: 30),

                        ElevatedButton.icon(
                          onPressed: () =>
                              _updateName(
                            context,
                            name,
                          ),
                          icon:
                              const Icon(Icons.edit),
                          label:
                              const Text('Editar Nome'),
                          style:
                              ElevatedButton.styleFrom(
                            minimumSize:
                                const Size(200, 50),
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