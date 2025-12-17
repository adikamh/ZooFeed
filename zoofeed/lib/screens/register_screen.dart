import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../database/auth_provider.dart';
import '../../pages/register_page.dart';
import './login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _zooNameController = TextEditingController();
  final _zooAddressController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _zooNameController.dispose();
    _zooAddressController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    // Validasi form
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
    
    if (_zooNameController.text.isEmpty) {
      _showError('Nama kebun binatang harus diisi');
      return;
    }
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    final result = await authProvider.register(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      fullName: _fullNameController.text.trim(),
      phone: _phoneController.text.trim(),
      zooName: _zooNameController.text.trim(),
      zooAddress: _zooAddressController.text.trim(),
    );

    if (result['success'] == true) {
      // Show success dialog
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Pendaftaran Berhasil'),
          content: const Text(
            'Silakan verifikasi email Anda sebelum login. '
            'Link verifikasi telah dikirim ke email Anda.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _goToLogin();
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _goToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return RegisterPage(
      emailController: _emailController,
      passwordController: _passwordController,
      confirmPasswordController: _confirmPasswordController,
      fullNameController: _fullNameController,
      phoneController: _phoneController,
      zooNameController: _zooNameController,
      zooAddressController: _zooAddressController,
      isLoading: authProvider.isLoading,
      error: authProvider.error,
      onRegisterPressed: _handleRegister,
      onLoginPressed: _goToLogin,
    );
  }
}