import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../database/auth_provider.dart' as local_auth;
import '../../pages/login_page.dart';
import '../screens/register_screen.dart';
import '../screens/forgot_password_screen.dart';
// email verification removed

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final authProvider = Provider.of<local_auth.AuthProvider>(context, listen: false);
    
    final result = await authProvider.login(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    if (!result['success']) return;
  }

  // Email verification popup removed

  void _goToRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const RegisterScreen(),
      ),
    );
  }

  void _goToForgotPassword() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ForgotPasswordScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<local_auth.AuthProvider>(context);

    return LoginPage(
      emailController: _emailController,
      passwordController: _passwordController,
      isLoading: authProvider.isLoading,
      error: authProvider.error,
      onLoginPressed: _handleLogin,
      onRegisterPressed: _goToRegister,
      onForgotPasswordPressed: _goToForgotPassword,
    );
  }
}