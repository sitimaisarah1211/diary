part of 'homepage.dart';

class HomePageState extends State<HomePage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _feelingController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  List<Map<String, dynamic>> _diaries = [];
  bool _isLoading = true;
  bool _isWeatherLoading = true;
  String? _weatherSummary;
  String? _lastFeelingSuggestion;
  Map<String, dynamic>? _lastDeletedDiary;
  int? _lastCreatedDiaryId;

  @override
  void initState() {
    super.initState();
    _refreshDiaries();
    _loadWeather();
    _loadPreferences();
  }

  @override
  void dispose() {
    _feelingController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _refreshDiaries() async {
    final data = await SQLHelper.getDiaries();
    setState(() {
      _diaries = data;
      _isLoading = false;
    });
  }

  Future<void> _loadWeather() async {
    setState(() {
      _isWeatherLoading = true;
    });

    try {
      final response = await http.get(Uri.parse(
          'https://api.open-meteo.com/v1/forecast?latitude=3.1390&longitude=101.6869&current_weather=true'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final current = data['current_weather'] as Map<String, dynamic>?;
        if (current != null) {
          final temperature = (current['temperature'] as num).toDouble();
          final weatherCode = current['weathercode'] as int;
          setState(() {
            _weatherSummary =
                '${temperature.toStringAsFixed(0)}°C • ${_weatherDescription(weatherCode)}';
          });
        }
      }
    } catch (_) {
      setState(() {
        _weatherSummary = 'Weather currently unavailable';
      });
    }

    setState(() {
      _isWeatherLoading = false;
    });
  }

  String _weatherDescription(int code) {
    if (code == 0) return 'Clear sky';
    if (code <= 3) return 'Partly cloudy';
    if (code <= 48) return 'Foggy';
    if (code <= 57) return 'Drizzle';
    if (code <= 67) return 'Rainy';
    if (code <= 77) return 'Snowy';
    if (code <= 86) return 'Freezing rain';
    return 'Windy';
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _lastFeelingSuggestion =
          prefs.getString('lastFeeling')?.trim().isNotEmpty == true
              ? prefs.getString('lastFeeling')
              : 'Happy';
    });
  }

  Future<void> _saveLastFeeling(String feeling) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lastFeeling', feeling);
    setState(() {
      _lastFeelingSuggestion = feeling;
    });
  }

  Color _moodCardColor(String? feeling) {
    final mood = feeling?.toLowerCase() ?? '';
    if (mood.contains('happy') ||
        mood.contains('joy') ||
        mood.contains('glad')) {
      return const Color(0xFF64FFDA);
    }
    if (mood.contains('sad') ||
        mood.contains('down') ||
        mood.contains('unhappy')) {
      return const Color(0xFFB2EBF2);
    }
    if (mood.contains('angry') ||
        mood.contains('mad') ||
        mood.contains('upset')) {
      return const Color(0xFFFFCDD2);
    }
    return const Color(0xFF80DEEA);
  }

  String _moodGifUrl(String? feeling) {
    final mood = feeling?.toLowerCase() ?? '';
    if (mood.contains('angry') || mood.contains('mad') || mood.contains('upset')) {
      return 'assets/images/angry.gif';
    }
    if (mood.contains('sad') || mood.contains('down') || mood.contains('unhappy')) {
      return 'assets/images/sad.gif';
    }
    if (mood.contains('happy') || mood.contains('joy') || mood.contains('glad')) {
      return 'assets/images/happy.gif';
    }
    return '';
  }

  Widget _moodAvatar(String? feeling) {
    final url = _moodGifUrl(feeling);
    final mood = feeling?.toLowerCase() ?? '';

    if (url.startsWith('assets/')) {
      return Image.asset(
        url,
        fit: BoxFit.cover,
        width: 40,
        height: 40,
        gaplessPlayback: true,
      );
    }

    Color iconColor = Colors.black;
    String emoji = '😊';
    if (mood.contains('sad') || mood.contains('down') || mood.contains('unhappy')) {
      emoji = '😢';
      iconColor = Colors.blueGrey;
    } else if (mood.contains('angry') || mood.contains('mad') || mood.contains('upset')) {
      emoji = '😠';
      iconColor = Colors.redAccent;
    }

    return Center(
      child: Text(
        emoji,
        style: TextStyle(fontSize: 24, color: iconColor),
      ),
    );
  }

  void _showForm(int? id) {
    if (id != null) {
      final existingDiary =
          _diaries.firstWhere((element) => element['id'] == id);
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
        return FractionallySizedBox(
          heightFactor: 0.55,
          child: Padding(
            padding: EdgeInsets.only(
              top: 20,
              left: 20,
              right: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    id == null ? 'Create Diary' : 'Update Diary',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
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
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _descriptionController,
                          decoration: const InputDecoration(
                            labelText: 'Description',
                            hintText: 'Write something about your day',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 5,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter a description';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
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
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(id == null ? 'Create New' : 'Update'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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
      await _saveLastFeeling(_feelingController.text.trim());
      _refreshDiaries();
      _feelingController.clear();
      _descriptionController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Diary created successfully!'),
            duration: const Duration(seconds: 2),
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
      await _saveLastFeeling(_feelingController.text.trim());
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
          content:
              const Text('Are you sure you want to delete this diary entry?'),
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
    setState(() {
      _diaries.removeWhere((element) => element['id'] == id);
    });

    if (mounted) {
      final messenger = ScaffoldMessenger.of(context);
      messenger.clearSnackBars();
      messenger.showSnackBar(
        SnackBar(
          content: const Text('Diary deleted'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
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

    try {
      await SQLHelper.deleteDiary(id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting diary: $e')),
        );
        _refreshDiaries();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Siti Maisarah Diary'),
        backgroundColor: const Color(0xFF009688),
        actions: [
          IconButton(
            icon: Icon(widget.isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: widget.onToggleTheme,
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18)),
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.cloud, color: Color(0xFF009688)),
                              const SizedBox(width: 10),
                              const Text(
                                'Quick Dashboard',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold),
                              ),
                              const Spacer(),
                              if (_isWeatherLoading)
                                const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _weatherSummary ??
                                'Loading the latest weather and mood summary...',
                            style: const TextStyle(fontSize: 15),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Suggested mood',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      _lastFeelingSuggestion ?? 'Happy',
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: () => _showForm(null),
                                icon: const Icon(Icons.add),
                                label: const Text('New entry'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF009688),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _refreshDiaries,
                    child: _diaries.isEmpty
                        ? ListView(
                            padding: const EdgeInsets.symmetric(
                                vertical: 16, horizontal: 12),
                            children: const [
                              Center(
                                child: Text(
                                  'No diaries yet. Tap + to add your first entry.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 16),
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(
                                vertical: 16, horizontal: 12),
                            itemCount: _diaries.length,
                            itemBuilder: (context, index) {
                              final diary = _diaries[index];
                              final cardColor =
                                  _moodCardColor(diary['feeling'] as String?);
                              return Card(
                                margin: const EdgeInsets.only(bottom: 14),
                                color: cardColor,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16)),
                                elevation: 4,
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(16),
                                  leading: CircleAvatar(
                                    radius: 28,
                                    backgroundColor: Colors.white,
                                    child: ClipOval(
                                      child: _moodAvatar(
                                          diary['feeling'] as String?),
                                    ),
                                  ),
                                  title: Text(
                                    diary['feeling'] ?? '',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: Colors.black),
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      '${diary['description'] ?? ''}\n\n${diary['createdAt'] ?? ''}',
                                      style: const TextStyle(
                                          color: Colors.black, height: 1.4),
                                    ),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit,
                                            color: Colors.teal),
                                        onPressed: () =>
                                            _showForm(diary['id'] as int),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete,
                                            color: Colors.redAccent),
                                        onPressed: () =>
                                            _deleteDiary(diary['id'] as int),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add),
        onPressed: () => _showForm(null),
      ),
    );
  }
}
