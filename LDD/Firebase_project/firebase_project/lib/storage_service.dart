import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String?> uploadProfilePicture(File file) async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) return null;

      final ref = _storage
          .ref()
          .child('profile_pictures')
          .child('${user.uid}.jpg');

      await ref.putFile(file);

      final downloadUrl = await ref.getDownloadURL();

      // salva URL no Firestore
      await _firestore.collection('users').doc(user.uid).update({
        'photo': downloadUrl,
      });

      return downloadUrl;
    } catch (e) {
      print('Erro upload foto: $e');
      return null;
    }
  }
}