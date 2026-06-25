import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Serviço responsável pelo CRUD das notas e pelas estatísticas do usuário.
///
/// Estrutura no Firestore:
///   /notes/{uid}/items/{noteId}
///     - titulo    (String)
///     - conteudo  (String)
///     - createdAt (Timestamp)
///     - favorito  (bool)
///
/// O contador de notas é mantido em /users/{uid}.notesCount usando
/// FieldValue.increment(1) ao criar e FieldValue.increment(-1) ao deletar.
class NoteService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser!.uid;

  CollectionReference<Map<String, dynamic>> get _itemsRef =>
      _firestore.collection('notes').doc(_uid).collection('items');

  DocumentReference<Map<String, dynamic>> get _userRef =>
      _firestore.collection('users').doc(_uid);

  /// Stream com todas as notas do usuário, mais recentes primeiro.
  Stream<QuerySnapshot<Map<String, dynamic>>> notesStream() {
    return _itemsRef.orderBy('createdAt', descending: true).snapshots();
  }

  /// Stream apenas com as notas favoritas (bônus: filtro com where).
  Stream<QuerySnapshot<Map<String, dynamic>>> favoritesStream() {
    return _itemsRef
        .where('favorito', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Adiciona uma nota e incrementa o contador de notas do usuário.
  Future<void> addNote({
    required String titulo,
    required String conteudo,
    bool favorito = false,
  }) async {
    final batch = _firestore.batch();

    final noteRef = _itemsRef.doc();
    batch.set(noteRef, {
      'titulo': titulo,
      'conteudo': conteudo,
      'createdAt': FieldValue.serverTimestamp(),
      'favorito': favorito,
    });

    batch.set(
      _userRef,
      {'notesCount': FieldValue.increment(1)},
      SetOptions(merge: true),
    );

    await batch.commit();
  }

  /// Alterna o estado de favorito de uma nota.
  Future<void> toggleFavorite(String noteId, bool current) async {
    await _itemsRef.doc(noteId).update({'favorito': !current});
  }

  /// Deleta uma nota e decrementa o contador de notas do usuário.
  Future<void> deleteNote(String noteId) async {
    final batch = _firestore.batch();

    batch.delete(_itemsRef.doc(noteId));
    batch.set(
      _userRef,
      {'notesCount': FieldValue.increment(-1)},
      SetOptions(merge: true),
    );

    await batch.commit();
  }
}
