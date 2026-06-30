import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'localization.dart';

class TrashPage extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onToggleTheme;
  final VoidCallback onLanguageChange;

  const TrashPage({
    super.key,
    required this.isDarkMode,
    required this.onToggleTheme,
    required this.onLanguageChange,
  });

  @override
  State<TrashPage> createState() => _TrashPageState();
}

class _TrashPageState extends State<TrashPage> {
  String _formatDate(DateTime date) => DateFormat('dd MMM yyyy, HH:mm').format(date);

  Future<void> _restoreEntry(String id) async {
    final doc = await FirebaseFirestore.instance.collection('deleted_diaries').doc(id).get();
    if (!doc.exists) return;
    final data = doc.data()!;
    data.remove('deletedAt');
    await FirebaseFirestore.instance.collection('diaries').doc(id).set(data);
    await FirebaseFirestore.instance.collection('deleted_diaries').doc(id).delete();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.translate('entry_restored')),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _permanentlyDelete(String id) async {
    await FirebaseFirestore.instance.collection('deleted_diaries').doc(id).delete();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Entri dipadam kekal'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _confirmPermanentDelete(String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Padam Kekal'),
        content: Text('Anda pasti mahu memadamkan entri ini secara kekal? Tindakan ini tidak boleh dibatalkan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.translate('cancel')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              _permanentlyDelete(id);
            },
            child: const Text('Padam Kekal', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.translate('trash')),
          backgroundColor: const Color(0xFF009688),
          foregroundColor: Colors.white,
        ),
        body: const Center(child: Text('Sila log masuk semula')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.translate('trash')),
        backgroundColor: const Color(0xFF009688),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(widget.isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: widget.onToggleTheme,
            color: Colors.white,
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('deleted_diaries')
            .where('userId', isEqualTo: user.uid)
            .orderBy('deletedAt', descending: true)
            .snapshots(),
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 60, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Ralat: ${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: const Text('Cuba Semula'),
                  ),
                ],
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.delete_outline, size: 60, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Tiada entri dalam tong sampah', style: TextStyle(fontSize: 16, color: Colors.grey)),
                ],
              ),
            );
          }

          final docs = snapshot.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (ctx, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              final id = docs[i].id;
              final feeling = data['feeling']?.toString() ?? 'Unknown';
              final description = data['description']?.toString() ?? '';
              final deletedAt = data['deletedAt'] as Timestamp?;
              final date = deletedAt != null ? deletedAt.toDate() : DateTime.now();

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                color: isDark ? Colors.grey[850] : Colors.white,
                child: ListTile(
                  leading: Text(
                    _getEmojiForFeeling(feeling),
                    style: const TextStyle(fontSize: 30),
                  ),
                  title: Text(
                    feeling,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(description, maxLines: 2, overflow: TextOverflow.ellipsis),
                      Text(
                        'Dipadam: ${_formatDate(date)}',
                        style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.restore, color: Colors.green),
                        onPressed: () => _restoreEntry(id),
                        tooltip: 'Pulihkan',
                      ),
                      IconButton(
                        icon: Icon(Icons.delete_forever, color: Colors.red),
                        onPressed: () => _confirmPermanentDelete(id),
                        tooltip: 'Padam kekal',
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _getEmojiForFeeling(String feeling) {
    switch (feeling) {
      case 'Happy': return '😊';
      case 'Sad': return '😢';
      case 'Angry': return '😠';
      case 'Excited': return '🤩';
      case 'Amazed': return '😲';
      default: return '😐';
    }
  }
}