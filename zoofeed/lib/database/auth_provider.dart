import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ========== TAMBAHKAN METHOD INI ==========
  void setCurrentUser(UserModel user) {
    _currentUser = user;
    notifyListeners();
  }

  // ========== TAMBAHKAN METHOD INI ==========
  Future<void> loadCurrentUser() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final userData = await getUserData(user.uid);
        if (userData != null) {
          _currentUser = userData;
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error loading current user: $e');
    }
  }

  // ========== TAMBAHKAN METHOD INI ==========
  Future<void> clearCurrentUser() {
    _currentUser = null;
    notifyListeners();
    return Future.value();
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // 1. Login dengan Firebase Auth
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user!;

      // No automatic verification email is sent here

      // 3. Get user data from Firestore
      final userData = await getUserData(user.uid);

      if (userData == null) {
        await _auth.signOut();
        _currentUser = null;
        _isLoading = false;
        _error = 'Data pengguna tidak ditemukan.';
        notifyListeners();
        return {
          'success': false,
          'message': 'Data pengguna tidak ditemukan.'
        };
      }

      // 4. Set current user
      _currentUser = userData;

      // 5. Check if user is active
      if (!_currentUser!.isActive) {
        await _auth.signOut();
        _currentUser = null;
        _isLoading = false;
        _error = 'Akun tidak aktif. Hubungi administrator.';
        notifyListeners();
        return {
          'success': false,
          'message': 'Akun tidak aktif. Hubungi administrator.'
        };
      }

      _isLoading = false;
      notifyListeners();

      return {
        'success': true,
        'message': 'Login berhasil!',
        'user': _currentUser,
      };

    } on FirebaseAuthException catch (e) {
      String message = 'Login gagal';
      
      switch (e.code) {
        case 'user-not-found':
          message = 'Email tidak ditemukan';
          break;
        case 'wrong-password':
          message = 'Password salah';
          break;
        case 'invalid-credential':
          message = 'Email atau password salah';
          break;
        case 'too-many-requests':
          message = 'Terlalu banyak percobaan. Coba lagi nanti';
          break;
        case 'user-disabled':
          message = 'Akun dinonaktifkan';
          break;
      }

      _error = message;
      _isLoading = false;
      _currentUser = null;
      notifyListeners();

      return {
        'success': false,
        'message': message,
      };

    } catch (e) {
      _error = 'Terjadi kesalahan. Coba lagi.';
      _isLoading = false;
      _currentUser = null;
      notifyListeners();

      return {
        'success': false,
        'message': 'Terjadi kesalahan. Coba lagi.',
      };
    }
  }

  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String zooName,
    required String zooAddress,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // 1. Create user in Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user!;



      // 3. Create zoo document
      final zooRef = await _firestore.collection('zoos').add({
        'name': zooName,
        'address': zooAddress,
        'phone': phone,
        'notification_config': {
          'feeding_reminder_times': ['08:00', '12:00', '16:00'],
          'reminder_before_minutes': 15,
          'daily_summary_time': '17:00',
          'missed_feeding_threshold_hours': 24,
        },
        'created_at': Timestamp.now(),
        'updated_at': Timestamp.now(),
      });

      // 4. Create user document
      await _firestore.collection('users').doc(user.uid).set({
        'email': email,
        'full_name': fullName,
        'role': 'admin',
        'zoo_id': zooRef.id,
        'phone': phone,
        'notification_settings': {
          'push_enabled': true,
          'email_enabled': true,
          'feeding_reminders': true,
          'daily_summary': true,
        },
        'is_active': true,
        'created_at': Timestamp.now(),
        'updated_at': Timestamp.now(),
      });

      // 5. Set current user (tapi belum verified)
      _currentUser = UserModel(
        uid: user.uid,
        email: email,
        fullName: fullName,
        role: 'admin',
        zooId: zooRef.id,
        phone: phone,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      _isLoading = false;
      notifyListeners();

      return {
        'success': true,
        'message': 'Pendaftaran berhasil!',
        'userId': user.uid,
        'zooId': zooRef.id,
      };

    } on FirebaseAuthException catch (e) {
      String message = 'Pendaftaran gagal';
      
      switch (e.code) {
        case 'email-already-in-use':
          message = 'Email sudah terdaftar';
          break;
        case 'invalid-email':
          message = 'Email tidak valid';
          break;
        case 'weak-password':
          message = 'Password terlalu lemah';
          break;
        case 'operation-not-allowed':
          message = 'Operasi tidak diizinkan';
          break;
      }

      _error = message;
      _isLoading = false;
      _currentUser = null;
      notifyListeners();

      return {
        'success': false,
        'message': message,
      };

    } catch (e) {
      _error = 'Terjadi kesalahan. Coba lagi.';
      _isLoading = false;
      _currentUser = null;
      notifyListeners();

      return {
        'success': false,
        'message': 'Terjadi kesalahan. Coba lagi.',
      };
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    _currentUser = null;
    _error = null;
    notifyListeners();
  }

  /// Soft-delete a user account by marking `is_active` = false in Firestore.
  /// Note: Deleting Firebase Authentication user requires admin SDK (server-side).
  Future<Map<String, dynamic>> deleteUserAccount(String userId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _firestore.collection('users').doc(userId).update({
        'is_active': false,
        'updated_at': Timestamp.now(),
      });

      // If we had the current user matching this id, clear it
      if (_currentUser != null && _currentUser!.uid == userId) {
        _currentUser = null;
      }

      _isLoading = false;
      notifyListeners();

      return {'success': true, 'message': 'Akun berhasil dinonaktifkan.'};
    } catch (e) {
      _error = 'Gagal menghapus akun';
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<void> forgotPassword(String email) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _auth.sendPasswordResetEmail(email: email);

      _isLoading = false;
      notifyListeners();
    } on FirebaseAuthException catch (e) {
      String message = 'Gagal mengirim email reset password';
      
      switch (e.code) {
        case 'user-not-found':
          message = 'Email tidak terdaftar';
          break;
        case 'invalid-email':
          message = 'Email tidak valid';
          break;
        case 'user-disabled':
          message = 'Akun dinonaktifkan';
          break;
      }

      _error = message;
      _isLoading = false;
      notifyListeners();
      rethrow;
    } catch (e) {
      _error = 'Terjadi kesalahan. Coba lagi.';
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<UserModel?> getUserData(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting user data: $e');
      return null;
    }
  }

  // ========== TAMBAHKAN METHOD INI ==========
  Future<Map<String, dynamic>> checkEmailVerification() async {
    try {
      return {'isVerified': false, 'message': 'Email verification not supported'};
    } catch (e) {
      return {'isVerified': false, 'message': 'Gagal memeriksa verifikasi email'};
    }
  }

  // ========== TAMBAHKAN METHOD INI ==========
  Future<Map<String, dynamic>> updateProfile({
    required String userId,
    String? fullName,
    String? phone,
    Map<String, dynamic>? notificationSettings,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final updateData = <String, dynamic>{
        'updated_at': Timestamp.now(),
      };

      if (fullName != null) updateData['full_name'] = fullName;
      if (phone != null) updateData['phone'] = phone;
      if (notificationSettings != null) {
        updateData['notification_settings'] = notificationSettings;
      }

      await _firestore.collection('users').doc(userId).update(updateData);

      // Update current user data
      if (_currentUser != null && _currentUser!.uid == userId) {
        if (fullName != null) _currentUser = _currentUser!.copyWith(fullName: fullName);
        if (phone != null) _currentUser = _currentUser!.copyWith(phone: phone);
      }

      _isLoading = false;
      notifyListeners();

      return {
        'success': true,
        'message': 'Profil berhasil diperbarui',
      };
    } catch (e) {
      _error = 'Gagal memperbarui profil';
      _isLoading = false;
      notifyListeners();
      
      return {
        'success': false,
        'message': 'Gagal memperbarui profil',
      };
    }
  }

  // ========== TAMBAHKAN METHOD INI ==========
  Future<void> resendVerificationEmail() async {
    try {
      // no-op: verification emails are not used by the app
    } catch (e) {
      debugPrint('Error resending verification email: $e');
      rethrow;
    }
  }

  // ========== TAMBAHKAN METHOD INI ==========
  Future<bool> isAuthenticated() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    
    await user.reload();
    return _auth.currentUser != null;
  }

  // ========== TAMBAHKAN METHOD INI ==========
  Future<void> clearError() {
    _error = null;
    notifyListeners();
    return Future.value();
  }
}