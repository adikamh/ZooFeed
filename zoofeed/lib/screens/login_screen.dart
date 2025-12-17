import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../database/auth_provider.dart';
import '../../pages/login_page.dart';
import '../../pages/admin_dashboard_page.dart';
import '../../pages/keeper_dashboard_page.dart';
import '../../models/user_model.dart';
import '../screens/register_screen.dart';
import '../screens/forgot_password_screen.dart';

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
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    final result = await authProvider.login(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    if (!result['success']) {
      // Error sudah ditangani oleh provider
      return;
    }

    // Login berhasil -> langsung navigasi berdasarkan role (jika tersedia)
    final user = result['user'] as UserModel?;
    if (user != null && mounted) {
      switch (user.role) {
        case 'admin':
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => AdminDashboardPage(user: user)),
          );
          break;
        case 'keeper':
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => KeeperDashboardPage(user: user)),
          );
          break;
        default:
          // Let AuthWrapper handle unknown roles or fallback
          break;
      }
    }
  }

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
    final authProvider = Provider.of<AuthProvider>(context);

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