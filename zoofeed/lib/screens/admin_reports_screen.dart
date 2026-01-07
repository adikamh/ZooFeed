import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AdminReportsScreen extends StatefulWidget {
  final UserModel currentUser;

  const AdminReportsScreen({super.key, required this.currentUser});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  bool _isRefreshing = false;

  Future<void> _refresh() async {
    setState(() => _isRefreshing = true);
    try {
      await FirebaseFirestore.instance
          .collection('reports')
          .where('zoo_id', isEqualTo: widget.currentUser.zooId)
          .get();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Data diperbarui')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memperbarui: $e')));
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reportsQuery = FirebaseFirestore.instance
        .collection('reports')
        .where('zoo_id', isEqualTo: widget.currentUser.zooId)
        .withConverter<Map<String, dynamic>>(
          fromFirestore: (snap, _) => snap.data() ?? {},
          toFirestore: (map, _) => map,
        );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Keeper'),
        actions: [
          IconButton(
            icon: _isRefreshing ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.refresh),
            onPressed: _isRefreshing ? null : _refresh,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: reportsQuery.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(child: Text('Belum ada laporan'));
          }

          // Sort client-side by created_at (descending) to avoid composite index requirement
          List<QueryDocumentSnapshot<Map<String, dynamic>>> sortedDocs = List.from(docs);
          DateTime? _parseCreatedAt(Map<String, dynamic> d) {
            final v = d['created_at'];
            if (v == null) return null;
            if (v is Timestamp) return v.toDate();
            if (v is DateTime) return v;
            if (v is String) {
              try {
                return DateTime.parse(v);
              } catch (_) {
                return null;
              }
            }
            return null;
          }

          sortedDocs.sort((a, b) {
            final da = _parseCreatedAt(a.data())?.millisecondsSinceEpoch ?? 0;
            final db = _parseCreatedAt(b.data())?.millisecondsSinceEpoch ?? 0;
            return db.compareTo(da);
          });

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: sortedDocs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final d = sortedDocs[index];
              final data = d.data();
              final isRead = data['is_read_by_admin'] == true;
              final createdAt = (data['created_at'] is Timestamp)
                  ? (data['created_at'] as Timestamp).toDate()
                  : (data['created_at'] is DateTime ? data['created_at'] as DateTime : null);

              return Card(
                color: isRead ? Colors.white : Colors.blue[50],
                child: ListTile(
                  title: Text(data['notes'] ?? '(tanpa catatan)', maxLines: 2, overflow: TextOverflow.ellipsis),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text('Keeper: ${data['keeper_id'] ?? '-'}'),
                      if (createdAt != null) Text('Waktu: ${createdAt.toLocal()}'),
                    ],
                  ),
                  trailing: isRead
                      ? const Icon(Icons.mark_email_read, color: Colors.green)
                      : const Icon(Icons.fiber_new, color: Colors.red),
                  onTap: () async {
                    // mark as read and open detail
                    try {
                      final now = DateTime.now();
                      await FirebaseFirestore.instance.collection('reports').doc(d.id).update({
                        'is_read_by_admin': true,
                        'read_at': Timestamp.fromDate(now),
                        'updated_at': Timestamp.fromDate(now),
                      });
                    } catch (_) {}

                    if (!context.mounted) return;
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Detail Laporan'),
                        content: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Keeper ID: ${data['keeper_id'] ?? '-'}'),
                              const SizedBox(height: 8),
                              const Text('Catatan:'),
                              const SizedBox(height: 6),
                              Text(data['notes'] ?? '-'),
                              const SizedBox(height: 12),
                              if (data['read_at'] != null) Text('Dibaca: ${data['read_at'].toString()}'),
                            ],
                          ),
                        ),
                        actions: [
                          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Tutup')),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
