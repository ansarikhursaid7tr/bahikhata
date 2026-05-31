import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../utils/constants.dart';

/// Authentication service wrapping Firebase Auth.
/// Supports username-based login by mapping username → username@bahikhata.local.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Stream of auth state changes.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Current Firebase user.
  User? get currentUser => _auth.currentUser;

  /// Sign in with username and password.
  /// Maps username to email format internally.
  Future<UserCredential> signIn(String username, String password) async {
    final email = Constants.usernameToEmail(username);
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _mapAuthException(e);
    }
  }

  /// Create a new user account (used by admin/owner).
  Future<UserCredential> createUser(String username, String password) async {
    final email = Constants.usernameToEmail(username);
    try {
      // Use a secondary Firebase app to prevent the current user from being logged out
      FirebaseApp app = await Firebase.initializeApp(
        name: 'SecondaryApp',
        options: Firebase.app().options,
      );
      
      final secondaryAuth = FirebaseAuth.instanceFor(app: app);
      final credential = await secondaryAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      await app.delete();
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _mapAuthException(e);
    }
  }

  /// Sign out.
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Reset password (sends to mapped email — only useful if real email).
  Future<void> resetPassword(String username) async {
    final email = Constants.usernameToEmail(username);
    await _auth.sendPasswordResetEmail(email: email);
  }

  /// Change password. Requires re-authentication with current password.
  Future<void> changePassword(String currentPassword, String newPassword) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user logged in');

    try {
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw _mapAuthException(e);
    }
  }

  /// Maps Firebase Auth exceptions to user-friendly messages.
  String _mapAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found with this username';
      case 'wrong-password':
        return 'Incorrect password';
      case 'invalid-credential':
        return 'Invalid username or password';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'too-many-requests':
        return 'Too many login attempts. Please try again later';
      case 'email-already-in-use':
        return 'This username is already taken';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters';
      default:
        return e.message ?? 'Authentication failed';
    }
  }
}
