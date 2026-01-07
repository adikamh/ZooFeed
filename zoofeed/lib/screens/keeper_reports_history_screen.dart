import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class KeeperReportsHistoryScreen extends StatefulWidget {
  final UserModel currentUser;

  const KeeperReportsHistoryScreen({super.key, required this.currentUser});

  @override
  State<KeeperReportsHistoryScreen> createState() => _KeeperReportsHistoryScreenState();
}

class _KeeperReportsHistoryScreenState extends State<KeeperReportsHistoryScreen> {
  bool _isRefreshing = false;

  Future<void> _refresh() async {
    setState(() => _isRefreshing = true);
    try {
      // perform an explicit fetch to ensure most recent data
      await FirebaseFirestore.instance
          .collection('reports')
          .where('keeper_id', isEqualTo: widget.currentUser.uid)
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
    final query = FirebaseFirestore.instance
      .collection('reports')
      .where('keeper_id', isEqualTo: widget.currentUser.uid);

    DateTime? _parseDynamicDate(dynamic v) {
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Laporan'),
        actions: [
          IconButton(
            icon: _isRefreshing ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.refresh),
            onPressed: _isRefreshing ? null : _refresh,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: query.snapshots(),
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

          // Sort client-side by created_at (descending) to avoid needing a composite index
          List<QueryDocumentSnapshot> sorted = List.from(docs);
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

          sorted.sort((a, b) {
            final da = _parseCreatedAt((a.data() as Map<String, dynamic>))?.millisecondsSinceEpoch ?? 0;
            final db = _parseCreatedAt((b.data() as Map<String, dynamic>))?.millisecondsSinceEpoch ?? 0;
            return db.compareTo(da);
          });

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: sorted.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final d = sorted[index];
              final data = d.data() as Map<String, dynamic>;
              final createdAt = _parseCreatedAt(data);

              final isRead = data['is_read_by_admin'] == true;
              final isSent = data['is_sent'] == true;

              // Determine status label: if admin has read the report, consider it 'Berhasil'
              final String statusLabel;
              final Color statusBg;
              if (isRead) {
                statusLabel = 'Berhasil';
                statusBg = Colors.green[50]!;
              } else if (isSent) {
                statusLabel = 'Terkirim';
                statusBg = Colors.green[50]!;
              } else {
                statusLabel = 'Gagal';
                statusBg = Colors.red[50]!;
              }

              return Card(
                color: isRead ? Colors.white : Colors.blue[50],
                child: ListTile(
                  title: const Text('Laporan', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 6),
                      if (data['notes'] != null && data['notes'].toString().isNotEmpty)
                        Text(
                          data['notes'],
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 6),
                      if (createdAt != null) Text(_formatDate(createdAt)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Chip(
                            label: Text(statusLabel),
                            backgroundColor: statusBg,
                          ),
                          const SizedBox(width: 8),
                          Chip(
                            label: Text(isRead ? 'Dibaca Admin' : 'Belum Dibaca'),
                            backgroundColor: isRead ? Colors.grey[200] : Colors.orange[50],
                          ),
                        ],
                      ),
                    ],
                  ),
                  onTap: () async {
                    if (!context.mounted) return;
                    await showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text('Detail Laporan', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                        content: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (data['notes'] != null && data['notes'].toString().isNotEmpty) ...[
                                Text('Catatan', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                                const SizedBox(height: 6),
                                Text(data['notes']),
                                const SizedBox(height: 12),
                              ],
                              Row(
                                children: [
                                  Icon(Icons.access_time, size: 18, color: Theme.of(context).colorScheme.primary),
                                  const SizedBox(width: 8),
                                  if (_parseDynamicDate(data['created_at']) != null)
                                    Text('Dibuat: ${_formatDate(_parseDynamicDate(data['created_at'])!)}', style: Theme.of(context).textTheme.bodySmall),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.remove_red_eye, size: 18, color: Theme.of(context).colorScheme.secondary),
                                  const SizedBox(width: 8),
                                  if (_parseDynamicDate(data['read_at']) != null)
                                    Text('Dibaca: ${_formatDate(_parseDynamicDate(data['read_at'])!)}', style: Theme.of(context).textTheme.bodySmall),
                                  if (_parseDynamicDate(data['read_at']) == null)
                                    Text('Belum dibaca', style: Theme.of(context).textTheme.bodySmall),
                                ],
                              ),
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

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
