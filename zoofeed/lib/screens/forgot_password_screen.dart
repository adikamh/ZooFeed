import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../database/auth_provider.dart';
import '../pages/forgot_password_page.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  String? _successMessage;
  // ignore: unused_field
  bool _hasSentEmail = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSendReset() async {
    if (_emailController.text.isEmpty || !_emailController.text.contains('@')) {
      _showError('Email tidak valid');
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    try {
      await authProvider.forgotPassword(_emailController.text.trim());
      
      setState(() {
        _successMessage = 'Link reset password telah dikirim ke ${_emailController.text.trim()}';
        _hasSentEmail = true;
      });
      
    } catch (e) {
      _showError('Gagal mengirim email reset password');
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

  void _goBackToLogin() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return ForgotPasswordPage(
      emailController: _emailController,
      isLoading: authProvider.isLoading,
      error: authProvider.error,
      successMessage: _successMessage,
      onSendResetPressed: _handleSendReset,
      onBackToLoginPressed: _goBackToLogin,
    );
  }
}