import 'package:flutter/material.dart';
import 'sql_helper.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // All diaries
  List<Map<String, dynamic>> _diaries = [];

  bool _isLoading = true;
  // This function is used to fetch all data from the database
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
    _refreshDiaries(); // Loading the diary when the app starts
  }

  final TextEditingController _feelingController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  // This function will be triggered when the floating button is pressed
  // It will also be triggered when you want to update a diary
  void _showForm(int? id) async {
    if (id != null) {
      // id == null -> create new diary
      // id != null -> update an existing diary
      final existingDiary =
          _diaries.firstWhere((element) => element['id'] == id);
      _feelingController.text = existingDiary['feeling'];
      _descriptionController.text = existingDiary['description'];
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
                // this will prevent the soft keyboard from covering the text fields
                bottom: MediaQuery.of(context).viewInsets.bottom + 120,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  TextField(
                    controller: _feelingController,
                    decoration: const InputDecoration(hintText: 'Feeling'),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  TextField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(hintText: 'Description'),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      // Save new diary
                      if (id == null) {
                        await _addDiary();
                      }

                      if (id != null) {
                        await _updateDiary(id);
                      }

                      // Clear the text fields
                      _feelingController.text = '';
                      _descriptionController.text = '';

                      // Close the bottom sheet
                      Navigator.of(context).pop();
                    },
                    child: Text(id == null ? 'Create New' : 'Update'),
                  )
                ],
              ),
            ));
  }

// Insert a new diary to the database
  Future<void> _addDiary() async {
    await SQLHelper.createDiary(
        _feelingController.text, _descriptionController.text);
    _refreshDiaries();
  }

  // Update an existing diary
  Future<void> _updateDiary(int id) async {
    await SQLHelper.updateDiary(
        id, _feelingController.text, _descriptionController.text);
    _refreshDiaries();
  }

  // Delete an item
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
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : ListView.builder(
              itemCount: _diaries.length,
              itemBuilder: (context, index) => Card(
                color: Colors.tealAccent,
                margin: const EdgeInsets.all(10),
                child: ListTile(
                    leading: CircleAvatar(
                              child: Image.asset('assets/images/happy.gif'),
                              backgroundColor: Colors.tealAccent,
                    ),
                    title: Text(_diaries[index]['feeling']),
                    subtitle: Text(_diaries[index]['description'] + '\n\n'+ _diaries[index]['createdAt']),
                    trailing: SizedBox(
                      width: 100,
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _showForm(_diaries[index]['id']),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () =>
                                _deleteDiary(_diaries[index]['id']),
                          ),
                        ],
                      ),
                    )),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => _showForm(null),
      ),
    );
  }
}