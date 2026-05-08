import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  bool _isLogin = true;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  // LOGIN COM GOOGLE
// LOGIN COM GOOGLE ATUALIZADO
  Future<void> _signInWithGoogle() async {
    try {
      // 1. Inicia o fluxo de login
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      
      if (googleUser == null) return; // Usuário cancelou o login

      // 2. Obtém os detalhes da autenticação
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // 3. Cria uma nova credencial para o Firebase
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 4. Faz o login no Firebase com a credencial do Google
      UserCredential userCred = await _auth.signInWithCredential(credential);
      
      // 5. Se for um novo usuário, cria o perfil no Firestore
      final doc = await _firestore.collection('users').doc(userCred.user!.uid).get();
      if (!doc.exists) {
        await _firestore.collection('users').doc(userCred.user!.uid).set({
          'name': googleUser.displayName,
          'createdAt': FieldValue.serverTimestamp(),
          'role': 'user',
        });
      }
    } catch (e) {
      print("ERRO DETALHADO: $e"); // Isso ajuda a ver o erro no terminal
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao entrar com Google: $e'))
      );
    }
  }

  // REDEFINIR SENHA
  Future<void> _resetPassword() async {
    if (_emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Insira o e-mail primeiro')));
      return;
    }
    await _auth.sendPasswordResetEmail(email: _emailController.text.trim());
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('E-mail de redefinição enviado!')));
  }

  Future<void> _submit() async {
    try {
      if (_isLogin) {
        await _auth.signInWithEmailAndPassword(
            email: _emailController.text.trim(), password: _passwordController.text.trim());
      } else {
        UserCredential cred = await _auth.createUserWithEmailAndPassword(
            email: _emailController.text.trim(), password: _passwordController.text.trim());
        
        await cred.user!.sendEmailVerification(); // VERIFICAÇÃO DE E-MAIL
        
        await _firestore.collection('users').doc(cred.user!.uid).set({
          'name': _nameController.text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
          'role': 'user',
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Verifique seu e-mail!')));
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? 'Erro')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isLogin ? 'Login' : 'Cadastro')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            children: [
              if (!_isLogin) TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Nome')),
              TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'E-mail')),
              TextField(controller: _passwordController, decoration: const InputDecoration(labelText: 'Senha'), obscureText: true),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: _submit, child: Text(_isLogin ? 'Entrar' : 'Cadastrar')),
              TextButton(onPressed: _resetPassword, child: const Text('Esqueci minha senha')),
              TextButton(onPressed: () => setState(() => _isLogin = !_isLogin), 
                         child: Text(_isLogin ? 'Criar conta' : 'Já tenho conta')),
              const Divider(),
              ElevatedButton.icon(
                icon: const Icon(Icons.login),
                label: const Text('Entrar com Google'),
                onPressed: _signInWithGoogle,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade100),
              ),
            ],
          ),
        ),
      ),
    );
  }
}