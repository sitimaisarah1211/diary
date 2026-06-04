part of 'homepage.dart';

class HomePageState extends State<HomePage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _feelingController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  List<Map<String, dynamic>> _diaries = [];
  bool _isLoading = true;
  Map<String, dynamic>? _lastDeletedDiary;
  int? _lastCreatedDiaryId;

  @override
  void initState() {
    super.initState();
    _refreshDiaries();
  }

  @override
  void dispose() {
    _feelingController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _refreshDiaries() async {
    final data = await SQLHelper.getDiaries();
    setState(() {
      _diaries = data;
      _isLoading = false;
    });
  }

  void _showForm(int? id) {
    if (id != null) {
      final existingDiary = _diaries.firstWhere((element) => element['id'] == id);
      _feelingController.text = existingDiary['feeling'] ?? '';
      _descriptionController.text = existingDiary['description'] ?? '';
    } else {
      _feelingController.clear();
      _descriptionController.clear();
    }

    showModalBottomSheet(
      context: context,
      elevation: 5,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  id == null ? 'Create Diary' : 'Update Diary',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _feelingController,
                  decoration: const InputDecoration(
                    labelText: 'Feeling',
                    hintText: 'e.g. Happy',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a feeling';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Write something about your day',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 4,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a description';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    if (!_formKey.currentState!.validate()) {
                      return;
                    }
                    if (id == null) {
                      await _addDiary();
                    } else {
                      await _updateDiary(id);
                    }
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(id == null ? 'Create New' : 'Update'),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _addDiary() async {
    try {
      final newId = await SQLHelper.createDiary(
        _feelingController.text.trim(),
        _descriptionController.text.trim(),
      );
      _lastCreatedDiaryId = newId;
      _refreshDiaries();
      _feelingController.clear();
      _descriptionController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Diary created successfully!'),
            action: SnackBarAction(
              label: 'Undo',
              textColor: Colors.amber,
              onPressed: () async {
                if (_lastCreatedDiaryId != null) {
                  await SQLHelper.deleteDiary(_lastCreatedDiaryId!);
                  _refreshDiaries();
                  _lastCreatedDiaryId = null;
                }
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating diary: $e')),
        );
      }
    }
  }

  Future<void> _updateDiary(int id) async {
    try {
      await SQLHelper.updateDiary(
        id,
        _feelingController.text.trim(),
        _descriptionController.text.trim(),
      );
      _refreshDiaries();
      _feelingController.clear();
      _descriptionController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Diary updated successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating diary: $e')),
        );
      }
    }
  }

  Future<void> _deleteDiary(int id) async {
    final diary = _diaries.firstWhere((element) => element['id'] == id);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm delete'),
          content: const Text('Are you sure you want to delete this diary entry?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    _lastDeletedDiary = Map<String, dynamic>.from(diary);
    await SQLHelper.deleteDiary(id);
    _refreshDiaries();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Diary deleted'),
          action: SnackBarAction(
            label: 'Undo',
            textColor: Colors.tealAccent,
            onPressed: () async {
              if (_lastDeletedDiary != null) {
                await SQLHelper.saveDiary(_lastDeletedDiary!);
                _refreshDiaries();
                _lastDeletedDiary = null;
              }
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Siti Maisarah Diary'),
        actions: [
          IconButton(
            icon: Icon(widget.isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: widget.onToggleTheme,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _diaries.isEmpty
              ? const Center(
                  child: Text(
                    'No diaries yet. Tap + to add your first entry.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                  itemCount: _diaries.length,
                  itemBuilder: (context, index) {
                    final diary = _diaries[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 4,
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.white,
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/happy.gif',
                              fit: BoxFit.cover,
                              width: 40,
                              height: 40,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(Icons.sentiment_satisfied, color: Colors.teal, size: 32);
                              },
                            ),
                          ),
                        ),
                        title: Text(
                          diary['feeling'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            '${diary['description'] ?? ''}\n\n${diary['createdAt'] ?? ''}',
                            style: const TextStyle(color: Colors.black87, height: 1.4),
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.teal),
                              onPressed: () => _showForm(diary['id'] as int),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.redAccent),
                              onPressed: () => _deleteDiary(diary['id'] as int),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add),
        onPressed: () => _showForm(null),
      ),
    );
  }
}
