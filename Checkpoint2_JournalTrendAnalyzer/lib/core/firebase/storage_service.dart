import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'firebase_bootstrap.dart';

/// Firebase Storage: uploads exported PDF reports and returns their
/// download URL.
class StorageService {
  const StorageService();

  Future<String> uploadReport(File file, String topic) async {
    if (!FirebaseBootstrap.isAvailable) {
      throw StateError('Firebase is not configured (see FIREBASE_SETUP.md).');
    }
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'guest';
    final slug = topic
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    final name =
        '${DateTime.now().millisecondsSinceEpoch}_${slug.isEmpty ? 'report' : slug}.pdf';
    final ref = FirebaseStorage.instance.ref('reports/$uid/$name');
    await ref.putFile(
      file,
      SettableMetadata(contentType: 'application/pdf'),
    );
    return ref.getDownloadURL();
  }
}
