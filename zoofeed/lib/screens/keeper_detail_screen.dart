import 'package:flutter/material.dart';
import 'edit_keeper_screen.dart';

class KeeperDetailScreen extends StatelessWidget {
  final Map<String, String> keeper;

  const KeeperDetailScreen({super.key, required this.keeper});

  @override
  Widget build(BuildContext context) {
    final isActive = keeper['status'] == 'active';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Keeper'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: isActive ? Colors.green[100] : Colors.grey[200],
                child: Icon(Icons.person, color: isActive ? Colors.green[800] : Colors.grey[600]),
              ),
              title: Text(keeper['name'] ?? '-'),
              subtitle: Text(keeper['email'] ?? '-'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.green[50] : Colors.red[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(isActive ? 'Aktif' : 'Nonaktif', style: TextStyle(color: isActive ? Colors.green[800] : Colors.red[800])),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text('ID: ${keeper['id'] ?? '-'}'),
            const SizedBox(height: 8),
            Text('Email: ${keeper['email'] ?? '-'}'),
            const SizedBox(height: 8),
            Text('Nama: ${keeper['name'] ?? '-'}'),
            const SizedBox(height: 24),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => EditKeeperScreen(keeper: keeper)),
                    );
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit'),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Kembali'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
