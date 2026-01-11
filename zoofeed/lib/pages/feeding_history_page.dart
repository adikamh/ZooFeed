import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:zoofeed/models/feeding_history.dart';

class FeedingHistoryPage extends StatelessWidget {
  const FeedingHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Pemberian Makan'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('feeding_histories')
            .orderBy('fed_at', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Terjadi kesalahan'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Belum ada riwayat'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final history = FeedingHistoryModel.fromFirestore(
                snapshot.data!.docs[index],
              );

              final date = DateFormat(
                'dd MMM yyyy, HH:mm',
              ).format(history.fedAt);

              return Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: ListTile(
                  leading: const Icon(Icons.restaurant),
                  title: Text(history.animalName),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Spesies: ${history.species}'),
                      Text('Kandang: ${history.enclosure}'),
                      if (history.notes.isNotEmpty)
                        Text('Catatan: ${history.notes}'),
                    ],
                  ),
                  trailing: Text(
                    date,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
