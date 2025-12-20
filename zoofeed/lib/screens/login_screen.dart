import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../database/auth_provider.dart' as local_auth;
import '../../pages/login_page.dart';
import '../screens/register_screen.dart';
import '../screens/forgot_password_screen.dart';
import '../pages/admin_dashboard_page.dart';
import '../pages/keeper_dashboard_page.dart';
import '../models/user_model.dart';

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
    // debug log
    debugPrint('Login result: $result');

    if (!result['success']) {
      final msg = (result['message'] ?? 'Login gagal').toString();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
      return;
    }

    final user = result['user'] as UserModel?;
    if (user != null) {
      if (!mounted) return;
      await _showSuccessPopup(result['message']?.toString() ?? 'Login berhasil');

      switch (user.role) {
        case 'admin':
          if (!mounted) return;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => AdminDashboardPage(user: user)),
          );
          break;
        case 'keeper':
          if (!mounted) return;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => KeeperDashboardPage(user: user)),
          );
          break;
        default:
          break;
      }
    }
  }

  Future<void> _showSuccessPopup(String message) async {
    // show dialog with scale + fade animation, auto dismiss after short delay
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Success',
      pageBuilder: (context, anim1, anim2) {
        return const SizedBox.shrink();
      },
      transitionBuilder: (context, a1, a2, child) {
        final curved = Curves.easeOutBack.transform(a1.value);
        return Opacity(
          opacity: a1.value,
          child: Transform.scale(
            scale: curved,
            child: Center(
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 220,
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, size: 80, color: Colors.green[700]),
                      const SizedBox(height: 12),
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 450),
    );

    // auto-dismiss after short delay
    await Future.delayed(const Duration(milliseconds: 900));
    if (mounted) Navigator.of(context, rootNavigator: true).pop();
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