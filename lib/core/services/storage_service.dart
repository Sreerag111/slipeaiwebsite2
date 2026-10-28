import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StorageService {
  StorageService({
    FirebaseStorage? storage,
    FirebaseAuth? auth,
  })  : _storage = storage ?? FirebaseStorage.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseStorage _storage;
  final FirebaseAuth _auth;

  String? get _userId => _auth.currentUser?.uid;

  String get _userPath {
    final uid = _userId;
    if (uid == null) {
      throw Exception('User not authenticated');
    }
    return 'users/$uid';
  }

  Future<String> uploadAvatar({
    required File imageFile,
    String? userId,
  }) async {
    final uid = userId ?? _userId;
    if (uid == null) {
      throw Exception('User not authenticated');
    }
    final ref = _storage.ref('$uid/avatar.jpg');
    final uploadTask = await ref.putFile(
      imageFile,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    return await uploadTask.ref.getDownloadURL();
  }

  Future<String> uploadFile({
    required File file,
    required String fileName,
    String? subfolder,
  }) async {
    final path = subfolder != null ? '$_userPath/$subfolder/$fileName' : '$_userPath/uploads/$fileName';
    final ref = _storage.ref(path);
    final uploadTask = await ref.putFile(file);
    return await uploadTask.ref.getDownloadURL();
  }

  Future<String> uploadBytes({
    required List<int> bytes,
    required String fileName,
    String? subfolder,
    String? contentType,
  }) async {
    final path = subfolder != null ? '$_userPath/$subfolder/$fileName' : '$_userPath/uploads/$fileName';
    final ref = _storage.ref(path);
    final uploadTask = await ref.putData(
      Uint8List.fromList(bytes),
      SettableMetadata(contentType: contentType ?? 'application/octet-stream'),
    );
    return await uploadTask.ref.getDownloadURL();
  }

  Future<void> deleteFile(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (_) {
      // File may not exist, ignore.
    }
  }
}
