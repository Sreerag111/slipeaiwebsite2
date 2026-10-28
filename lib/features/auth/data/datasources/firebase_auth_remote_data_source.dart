import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';

import 'auth_remote_data_source.dart';
import '../models/app_user_model.dart';

class FirebaseAuthRemoteDataSource implements AuthRemoteDataSource {
  static const String _serverClientId =
      '478220186287-u1gvbdqjc8d0u7hdq7rcm1hk9vc4dnvi.apps.googleusercontent.com';

  final firebase_auth.FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  FirebaseAuthRemoteDataSource({
    firebase_auth.FirebaseAuth? auth,
    GoogleSignIn? googleSignIn,
  })  : _auth = auth ?? firebase_auth.FirebaseAuth.instance,
        _googleSignIn = googleSignIn ??
            GoogleSignIn(serverClientId: _serverClientId);

  @override
  Future<AuthSessionModel?> getSessionUser({
    required String? token,
    required AppUserModel? cachedUser,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      return null;
    }
    return AuthSessionModel(
      user: _mapFirebaseUser(user),
      token: user.uid,
    );
  }

  @override
  Future<AuthSessionModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw Exception('Login failed. Please try again.');
      }
      return AuthSessionModel(
        user: _mapFirebaseUser(user),
        token: user.uid,
      );
    } on firebase_auth.FirebaseAuthException catch (e) {
      if (e.code == 'invalid-credential' ||
          e.code == 'user-not-found' ||
          e.code == 'wrong-password') {
        throw Exception(
          'Incorrect email or password. If you signed up with Google, try "Continue with Google" instead.',
        );
      }
      throw Exception(e.message ?? 'Login failed. Please try again.');
    }
  }

  @override
  Future<AuthSessionModel> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw Exception('Registration failed. Please try again.');
      }
      await user.updateDisplayName(name.trim());
      return AuthSessionModel(
        user: _mapFirebaseUser(user),
        token: user.uid,
      );
    } on firebase_auth.FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        throw Exception(
          'An account already exists with this email. Try logging in, or use "Continue with Google" if you signed up that way.',
        );
      }
      throw Exception(e.message ?? 'Registration failed. Please try again.');
    }
  }

  @override
  Future<AppUserModel> updateProfile({
    required AppUserModel user,
    required String? token,
  }) async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) {
      throw Exception('You are not logged in.');
    }
    await firebaseUser.updateDisplayName(user.name);
    if (user.avatarUrl != null && user.avatarUrl!.isNotEmpty) {
      await firebaseUser.updatePhotoURL(user.avatarUrl);
    }
    return _mapFirebaseUser(firebaseUser);
  }

  @override
  Future<void> logout({required String? token}) async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  @override
  Future<AuthSessionModel> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Google sign-in was cancelled.');
      }
      final googleAuth = await googleUser.authentication;
      final credential = firebase_auth.GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );
      final result = await _auth.signInWithCredential(credential);
      final user = result.user;
      if (user == null) {
        throw Exception('Google sign-in failed. Please try again.');
      }
      return AuthSessionModel(
        user: _mapFirebaseUser(user),
        token: user.uid,
      );
    } on firebase_auth.FirebaseAuthException catch (e) {
      if (e.code == 'account-exists-with-different-credential') {
        throw Exception(
          'This email is already registered. Please sign in with your password instead.',
        );
      }
      throw Exception(e.message ?? 'Google sign-in failed. Please try again.');
    }
  }

  AppUserModel _mapFirebaseUser(firebase_auth.User user) {
    return AppUserModel(
      name: user.displayName ?? user.email?.split('@').first ?? '',
      email: user.email ?? '',
      avatarUrl: user.photoURL,
    );
  }
}
