import 'package:flutter/material.dart';
import 'sql_helper.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Semua rekod diari
  List<Map<String, dynamic>> _diaries = [];

  bool _isLoading = true;

  // Fungsi untuk mengambil semua data dari database
  void _refreshDiaries() async {
    final data = await SQLHelper.getDiaries();
    setState(() {
      _diaries = data;
      _isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _refreshDiaries(); // Memuatkan data semasa aplikasi bermula
  }

  final TextEditingController _feelingController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  // Fungsi untuk memaparkan borang (BottomSheet) sama ada Tambah Baru @ Kemaskini
  void _showForm(int? id) async {
    if (id != null) {
      // Jika id ada, ambil data sedia ada untuk dikemaskini
      final existingDiary =
          _diaries.firstWhere((element) => element['id'] == id);
      _feelingController.text = existingDiary['feeling'];
      _descriptionController.text = existingDiary['description'];
    } else {
      // Jika id tiada (kosong), bersihkan borang
      _feelingController.text = '';
      _descriptionController.text = '';
    }

    showModalBottomSheet(
      context: context,
      elevation: 5,
      isScrollControlled: true,
      builder: (_) => Container(
        padding: EdgeInsets.only(
          top: 15,
          left: 15,
          right: 15,
          // Mengelakkan papan kekunci (soft-keyboard) daripada menutup ruangan teks
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            TextField(
              controller: _feelingController,
              decoration: const InputDecoration(hintText: 'Feeling'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(hintText: 'Description'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                // Simpan diari baru jika id == null
                if (id == null) {
                  await _addDiary();
                }

                // Kemaskini jika id != null
                if (id != null) {
                  await _updateDiary(id);
                }

                // Bersihkan teks controllers
                _feelingController.text = '';
                _descriptionController.text = '';

                // Tutup borang BottomSheet
                Navigator.of(context).pop();
              },
              child: Text(id == null ? 'Create New' : 'Update'),
            )
          ],
        ),
      ),
    );
  }

  // Tambah rekod baru ke pangkalan data
  Future<void> _addDiary() async {
    await SQLHelper.createDiary(
        _feelingController.text, _descriptionController.text);
    _refreshDiaries();
  }

  // Kemaskini rekod sedia ada
  Future<void> _updateDiary(int id) async {
    await SQLHelper.updateDiary(
        id, _feelingController.text, _descriptionController.text);
    _refreshDiaries();
  }

  // Padam rekod diari
  Future<void> _deleteDiary(int id) async {
    await SQLHelper.deleteDiary(id);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Successfully deleted a diary!'),
    ));
    _refreshDiaries();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Siti Maisarah Diary'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _diaries.isEmpty
              ? const Center(
                  child: Text('No diaries found. Click + to add one!'),
                )
              : ListView.builder(
                  itemCount: _diaries.length,
                  itemBuilder: (context, index) => Card(
                    color: const Color(0xFF64FFDA), // Warna Teal Cerah (TealAccent)
                    margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                    elevation: 3,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.white,
                        child: Image.asset(
                          'assets/images/happy.gif',
                          errorBuilder: (context, error, stackTrace) {
                            // Jika gambar fail tiada, ia akan memaparkan ikon emoji sebagai pengganti keselamatan
                            return const Icon(Icons.sentiment_satisfied, color: Colors.teal);
                          },
                        ),
                      ),
                      title: Text(
                        _diaries[index]['feeling'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '${_diaries[index]['description'] ?? ""}\n\n${_diaries[index]['createdAt'] ?? ""}',
                        style: const TextStyle(color: Colors.black54),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min, // Penting supaya butang rapat ke kanan
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.black54),
                            onPressed: () => _showForm(_diaries[index]['id']),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.black54),
                            onPressed: () => _deleteDiary(_diaries[index]['id']),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
        onPressed: () => _showForm(null),
      ),
    );
  }
}