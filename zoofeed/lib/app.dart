import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'database/auth_provider.dart' as local_auth; // Tambahkan alias
import 'screens/login_screen.dart';
import 'pages/admin_dashboard_page.dart';
import 'pages/keeper_dashboard_page.dart';
import 'models/user_model.dart';

class ZooFeederApp extends StatelessWidget {
  const ZooFeederApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => local_auth.AuthProvider()), // Gunakan alias
      ],
      child: MaterialApp(
        title: 'ZooFeeder',
        theme: ThemeData(
          primarySwatch: Colors.green,
          appBarTheme: const AppBarTheme(
            elevation: 0,
            backgroundColor: Colors.white,
            iconTheme: IconThemeData(color: Colors.black),
            titleTextStyle: TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        debugShowCheckedModeBanner: false,
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<local_auth.AuthProvider>(context); // Gunakan alias
    
    return StreamBuilder<User?>(
      stream: authProvider.authStateChanges,
      builder: (context, snapshot) {
        // Loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        // Error state
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 60,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Terjadi Kesalahan',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    },
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            ),
          );
        }
        
        // User is logged in
        if (snapshot.hasData && snapshot.data != null) {
          final user = snapshot.data!;
          
          // No mandatory email verification required — proceed to load user data
          // Get user data and redirect based on role
          return FutureBuilder<UserModel?>(
            future: authProvider.getUserData(user.uid),
            builder: (context, userSnapshot) {
              // Loading state for user data
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              
              // Error state for user data
              if (userSnapshot.hasError) {
                return Scaffold(
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 60,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Gagal Memuat Data Pengguna',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: Text(
                            userSnapshot.error.toString(),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () async {
                            await authProvider.logout();
                          },
                          child: const Text('Logout'),
                        ),
                      ],
                    ),
                  ),
                );
              }
              
              // User data loaded successfully
              if (userSnapshot.hasData && userSnapshot.data != null) {
                final userData = userSnapshot.data!;
                
                // Set current user in provider
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (authProvider.currentUser == null) {
                    authProvider.setCurrentUser(userData);
                  }
                });
                
                // Redirect based on role
                switch (userData.role) {
                  case 'admin':
                    return AdminDashboardPage(user: userData);
                  case 'keeper':
                    return KeeperDashboardPage(user: userData);
                  default:
                    // Unknown role - show error and logout option
                    return Scaffold(
                      appBar: AppBar(title: const Text('Role Tidak Dikenal')),
                      body: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.warning_amber_outlined,
                              size: 80,
                              color: Colors.orange,
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Role Tidak Valid',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 40),
                              child: Text(
                                'Role pengguna tidak dikenali. '
                                'Silakan hubungi administrator.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                            const SizedBox(height: 30),
                            ElevatedButton(
                              onPressed: () async {
                                await authProvider.logout();
                              },
                              child: const Text('Logout'),
                            ),
                          ],
                        ),
                      ),
                    );
                }
              }
              
              // No user data found
              return Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.person_off_outlined,
                        size: 60,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Data Pengguna Tidak Ditemukan',
                        style: TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () async {
                          await authProvider.logout();
                        },
                        child: const Text('Kembali ke Login'),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }
        
        // User is not logged in
        return const LoginScreen();
      },
    );
  }
}

// Email verification UI removed