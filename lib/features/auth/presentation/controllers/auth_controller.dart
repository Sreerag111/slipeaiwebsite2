import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../../../features/chat/presentation/controllers/chat_controller.dart';
import '../../../chat/data/datasources/chat_storage_data_source.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/usecases/bootstrap_auth_use_case.dart';
import '../../domain/usecases/google_sign_in_use_case.dart';
import '../../domain/usecases/login_use_case.dart';
import '../../domain/usecases/logout_use_case.dart';
import '../../domain/usecases/register_use_case.dart';
import '../../domain/usecases/update_profile_use_case.dart';

class AuthController extends GetxController {
  AuthController({
    required BootstrapAuthUseCase bootstrapAuthUseCase,
    required LoginUseCase loginUseCase,
    required RegisterUseCase registerUseCase,
    required UpdateProfileUseCase updateProfileUseCase,
    required LogoutUseCase logoutUseCase,
    required GoogleSignInUseCase googleSignInUseCase,
  })  : _bootstrapAuthUseCase = bootstrapAuthUseCase,
        _loginUseCase = loginUseCase,
        _registerUseCase = registerUseCase,
        _updateProfileUseCase = updateProfileUseCase,
        _logoutUseCase = logoutUseCase,
        _googleSignInUseCase = googleSignInUseCase;

  final BootstrapAuthUseCase _bootstrapAuthUseCase;
  final LoginUseCase _loginUseCase;
  final RegisterUseCase _registerUseCase;
  final UpdateProfileUseCase _updateProfileUseCase;
  final LogoutUseCase _logoutUseCase;
  final GoogleSignInUseCase _googleSignInUseCase;

  final Rxn<AppUser> _currentUser = Rxn<AppUser>();
  final RxBool _isLoading = true.obs;
  final RxnString _errorMessage = RxnString();

  AppUser? get currentUser => _currentUser.value;
  bool get isLoading => _isLoading.value;
  bool get isLoggedIn => _currentUser.value != null;
  String? get errorMessage => _errorMessage.value;

  Future<void> bootstrap() async {
    _setLoading(true);
    try {
      _currentUser.value = await _bootstrapAuthUseCase();
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _errorMessage.value = null;
    try {
      _currentUser.value = await _loginUseCase(
        email: email,
        password: password,
      );
      return true;
    } catch (error) {
      _errorMessage.value = error.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _errorMessage.value = null;
    try {
      _currentUser.value = await _registerUseCase(
        name: name,
        email: email,
        password: password,
      );
      return true;
    } catch (error) {
      _errorMessage.value = error.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateProfile(AppUser updated) async {
    _setLoading(true);
    _errorMessage.value = null;
    try {
      _currentUser.value = await _updateProfileUseCase(updated);
    } catch (error) {
      _errorMessage.value = error.toString().replaceFirst('Exception: ', '');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    _errorMessage.value = null;
    try {
      _currentUser.value = await _googleSignInUseCase();
      return true;
    } catch (error) {
      final msg = error.toString().replaceFirst('Exception: ', '');
      debugPrint('[GoogleSignIn] Error: $msg');
      _errorMessage.value = msg;
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    _setLoading(true);
    try {
      await _logoutUseCase();
      _currentUser.value = null;
      Get.find<ChatController>().returnToHome();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteAccount() async {
    _setLoading(true);
    _errorMessage.value = null;
    try {
      final firebaseUser = firebase_auth.FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        final uid = firebaseUser.uid;

        // 1. Permanently delete user records from Firestore
        try {
          final firestore = FirebaseFirestore.instance;
          final userDoc = firestore.collection('users').doc(uid);

          // Subcollection: history
          final historySnap = await userDoc.collection('history').get();
          for (final doc in historySnap.docs) {
            await doc.reference.delete();
          }

          // Subcollection: threads
          final threadSnap = await userDoc.collection('threads').get();
          for (final doc in threadSnap.docs) {
            await doc.reference.delete();
          }

          // Subcollection: enhancements
          final enhSnap = await userDoc.collection('enhancements').get();
          for (final doc in enhSnap.docs) {
            await doc.reference.delete();
          }

          // Delete user root document
          await userDoc.delete();
        } catch (e) {
          debugPrint('[DeleteAccount] Firestore cleanup non-fatal error: $e');
        }

        // 2. Delete user account from Firebase Authentication
        await firebaseUser.delete();
      }

      // 3. Clear session and log out
      await _logoutUseCase();
      _currentUser.value = null;

      if (Get.isRegistered<ChatStorageDataSource>()) {
        try {
          await Get.find<ChatStorageDataSource>().clearHistory();
        } catch (_) {}
      }

      Get.find<ChatController>().returnToHome();
    } on firebase_auth.FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw Exception(
          'For security, deleting your account requires a recent sign-in. Please log out and sign back in, then try deleting again, or email paceai.support@gmail.com.',
        );
      }
      throw Exception(
        e.message ?? 'Failed to delete account. Please try again or email paceai.support@gmail.com.',
      );
    } catch (error) {
      final msg = error.toString().replaceFirst('Exception: ', '');
      _errorMessage.value = msg;
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  void clearError() {
    _errorMessage.value = null;
  }

  void _setLoading(bool value) {
    _isLoading.value = value;
  }
}

