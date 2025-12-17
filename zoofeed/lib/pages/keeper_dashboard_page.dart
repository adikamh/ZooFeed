import 'package:flutter/material.dart';
import '../../models/user_model.dart';

class KeeperDashboardPage extends StatelessWidget {
  final UserModel user;

  const KeeperDashboardPage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Keeper'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Halo, ${user.fullName}!',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text('Role: ${user.role}'),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                // Logout logic
              },
              child: const Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }
}