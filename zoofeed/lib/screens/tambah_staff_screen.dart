import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../database/auth_provider.dart' as local_auth;
import '../pages/tambah_staff_page.dart';

class TambahStaffScreen extends StatefulWidget {
  final String currentUserZooId;

  const TambahStaffScreen({
    super.key,
    required this.currentUserZooId,
  });

  @override
  State<TambahStaffScreen> createState() => _TambahStaffScreenState();
}

class _TambahStaffScreenState extends State<TambahStaffScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleAddStaff() async {
    if (_fullNameController.text.isEmpty) {
      _showError('Nama lengkap harus diisi');
      return;
    }
    
    if (_emailController.text.isEmpty || !_emailController.text.contains('@')) {
      _showError('Email tidak valid');
      return;
    }
    
    if (_passwordController.text.length < 6) {
      _showError('Password minimal 6 karakter');
      return;
    }
    
    if (_passwordController.text != _confirmPasswordController.text) {
      _showError('Password tidak cocok');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      
      final auth = FirebaseAuth.instance;
      final userCredential = await auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final user = userCredential.user!;

      
      final firestore = FirebaseFirestore.instance;
      
      await firestore.collection('users').doc(user.uid).set({
        'email': _emailController.text.trim(),
        'full_name': _fullNameController.text.trim(),
        'role': 'keeper',
        'zoo_id': widget.currentUserZooId,
        'phone': _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
        'notification_settings': {
          'push_enabled': true,
          'email_enabled': true,
          'feeding_reminders': true,
          'daily_summary': true,
        },
        'is_active': true,
        'created_at': Timestamp.now(),
        'updated_at': Timestamp.now(),
        'created_by': Provider.of<local_auth.AuthProvider>(context, listen: false).currentUser?.uid,
      });

      if (!mounted) return;
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Keeper Berhasil Ditambahkan'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Keeper baru telah berhasil ditambahkan ke sistem.'),
              const SizedBox(height: 12),
              Text(
                'Email: ${_emailController.text}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                'Keeper dapat langsung login menggunakan email dan password yang dibuat.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );

    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Gagal menambahkan keeper';
      
      switch (e.code) {
        case 'email-already-in-use':
          errorMessage = 'Email sudah terdaftar';
          break;
        case 'invalid-email':
          errorMessage = 'Email tidak valid';
          break;
        case 'weak-password':
          errorMessage = 'Password terlalu lemah';
          break;
        case 'operation-not-allowed':
          errorMessage = 'Operasi tidak diizinkan';
          break;
        default:
          errorMessage = e.message ?? 'Terjadi kesalahan';
      }
      
      _showError(errorMessage);
      
    } on FirebaseException catch (e) {
      _showError('Gagal menyimpan data: ${e.message}');
      
    } catch (e) {
      _showError('Terjadi kesalahan. Coba lagi.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    setState(() => _error = message);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _goBack() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return TambahStaffPage(
      emailController: _emailController,
      passwordController: _passwordController,
      confirmPasswordController: _confirmPasswordController,
      fullNameController: _fullNameController,
      phoneController: _phoneController,
      isLoading: _isLoading,
      error: _error,
      onAddStaffPressed: _handleAddStaff,
      onCancelPressed: _goBack,
    );
  }
}