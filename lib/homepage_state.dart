part of 'homepage.dart';

class HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> _diaries = [];
  bool _isLoading = true;
  String? _weatherSummary;
  String? _lastFeelingSuggestion;

  @override
  void initState() {
    super.initState();
    _refreshDiaries();
    _loadWeather();
    _loadPreferences();
  }

  Future<void> _refreshDiaries() async {
    final data = await SQLHelper.getDiaries();
    setState(() {
      _diaries = data;
      _isLoading = false;
    });
  }

  Future<void> _loadWeather() async {
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
            _weatherSummary = '${temperature.toStringAsFixed(0)}°C • ${_weatherDescription(weatherCode)}';
          });
        }
      }
    } catch (_) {
      setState(() {
        _weatherSummary = 'Weather currently unavailable';
      });
    }
  }

  String _weatherDescription(int code) {
    if (code == 0) return 'Clear sky';
    if (code <= 3) return 'Partly cloudy';
    if (code <= 48) return 'Foggy';
    if (code <= 57) return 'Drizzle';
    if (code <= 67) return 'Rainy';
    if (code <= 77) return 'Snowy';
    return 'Windy';
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _lastFeelingSuggestion = prefs.getString('lastFeeling')?.trim().isNotEmpty == true
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

  Color _moodCardColor(String? feeling, bool isDark) {
    final mood = feeling?.toLowerCase() ?? '';
    if (isDark) {
      if (mood.contains('happy')) return const Color(0xFF004D40);
      if (mood.contains('sad')) return const Color(0xFF006064);
      if (mood.contains('angry')) return const Color(0xFFB71C1C);
      return const Color(0xFF37474F);
    } else {
      if (mood.contains('happy')) return const Color(0xFF64FFDA);
      if (mood.contains('sad')) return const Color(0xFFB2EBF2);
      if (mood.contains('angry')) return const Color(0xFFFFCDD2);
      return const Color(0xFF80DEEA);
    }
  }

  Color _textColorForMood(String? feeling, bool isDark) {
    if (isDark) return Colors.white;
    final mood = feeling?.toLowerCase() ?? '';
    if (mood.contains('angry')) return Colors.red.shade900;
    return Colors.black87;
  }

  Widget _moodAvatar(String? feeling) {
    final mood = feeling?.toLowerCase() ?? '';
    String emoji = '😊';
    if (mood.contains('sad')) emoji = '😢';
    if (mood.contains('angry')) emoji = '😠';
    return Center(child: Text(emoji, style: const TextStyle(fontSize: 24)));
  }

  void _showForm(int? id) async {
    String title = id == null ? 'Create Diary' : 'Update Diary';
    String submitLabel = id == null ? 'Create New' : 'Update';
    String? initialFeeling;
    String? initialDescription;

    if (id != null) {
      final existingDiary = _diaries.firstWhere((element) => element['id'] == id);
      initialFeeling = existingDiary['feeling'] as String?;
      initialDescription = existingDiary['description'] as String?;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DiaryFormPage(
          isDarkMode: widget.isDarkMode,
          title: title,
          initialFeeling: initialFeeling,
          initialDescription: initialDescription,
          submitLabel: submitLabel,
          onSave: (feeling, description) async {
            int newId;
            if (id == null) {
              newId = await SQLHelper.createDiary(feeling, description);
              _showUndoSnackBar(newId, feeling, description, isCreation: true);
            } else {
              await SQLHelper.updateDiary(id, feeling, description);
            }
            await _saveLastFeeling(feeling);
          },
        ),
      ),
    );
    _refreshDiaries();
  }

  // DIBAIKI: Dipaksa bersihkan SnackBar lama dan tetapkan masa tegar 2 saat
  void _showUndoSnackBar(int id, String feeling, String description, {required bool isCreation}) {
    if (!mounted) return;
    
    // Padam sebarang SnackBar bertindih yang membuatkannya rasa lama
    ScaffoldMessenger.of(context).clearSnackBars(); 
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isCreation ? 'Diary created successfully!' : 'Diary entry deleted.'),
        duration: const Duration(seconds: 2), // Tepat 2 saat sahaja!
        action: SnackBarAction(
          label: 'UNDO',
          textColor: Colors.tealAccent,
          onPressed: () async {
            if (isCreation) {
              await SQLHelper.deleteDiary(id);
            } else {
              await SQLHelper.createDiary(feeling, description);
            }
            _refreshDiaries();
          },
        ),
      ),
    );
  }

  Future<void> _confirmDeleteDiary(int id) async {
    final existingDiary = _diaries.firstWhere((element) => element['id'] == id);
    final backupFeeling = existingDiary['feeling'] ?? '';
    final backupDescription = existingDiary['description'] ?? '';

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: const Text('Are you sure you want to delete this diary?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('No', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Yes', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await SQLHelper.deleteDiary(id);
      _refreshDiaries();
      _showUndoSnackBar(id, backupFeeling, backupDescription, isCreation: false);
    }
  }

  void _handleLogout() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => LoginPage(
          isDarkMode: widget.isDarkMode,
          onToggleTheme: widget.onToggleTheme,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Siti Maisarah Diary'),
        backgroundColor: const Color(0xFF009688),
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: widget.onToggleTheme,
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Logout',
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_weatherSummary ?? 'Loading weather...',
                              style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                          const SizedBox(height: 10),
                          Text('Suggested mood: ${_lastFeelingSuggestion ?? "Happy"}',
                              style: TextStyle(color: isDark ? Colors.white70 : Colors.black54)),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: _diaries.isEmpty
                      ? Center(child: Text('No diary entries found.', style: TextStyle(color: isDark ? Colors.white60 : Colors.black54)))
                      : ListView.builder(
                          itemCount: _diaries.length,
                          itemBuilder: (context, index) {
                            final diary = _diaries[index];
                            final tileColor = _textColorForMood(diary['feeling'], isDark);
                            return Card(
                              color: _moodCardColor(diary['feeling'], isDark),
                              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: isDark ? Colors.grey[800] : Colors.white,
                                  child: _moodAvatar(diary['feeling']),
                                ),
                                title: Text(diary['feeling'] ?? '', 
                                    style: TextStyle(fontWeight: FontWeight.bold, color: tileColor)),
                                subtitle: Text(diary['description'] ?? '', 
                                    style: TextStyle(color: tileColor.withOpacity(0.9))),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit), 
                                      color: tileColor,
                                      onPressed: () => _showForm(diary['id'])
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete), 
                                      color: tileColor,
                                      onPressed: () => _confirmDeleteDiary(diary['id'])
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.teal,
        onPressed: () => _showForm(null),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

// =========================================================================
// DIARY FORM PAGE (DROPDOWN + INTEGRATED VOICE INPUT)
// =========================================================================
class DiaryFormPage extends StatefulWidget {
  final bool isDarkMode;
  final String title;
  final String? initialFeeling;
  final String? initialDescription;
  final String submitLabel;
  final Future<void> Function(String feeling, String description) onSave;

  const DiaryFormPage({
    super.key,
    required this.isDarkMode,
    required this.title,
    this.initialFeeling,
    this.initialDescription,
    required this.submitLabel,
    required this.onSave,
  });

  @override
  State<DiaryFormPage> createState() => _DiaryFormPageState();
}

class _DiaryFormPageState extends State<DiaryFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _customFeelingController;
  late final TextEditingController _descriptionController;
  bool _isSaving = false;

  final List<String> _moodOptions = ['Happy', 'Sad', 'Angry', 'Other'];
  String? _selectedMood;
  bool _isCustomMood = false;

  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  bool _isListeningDesc = false;
  String _sentimentReport = "No analysis performed yet.";

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(text: widget.initialDescription ?? '');
    
    final initial = widget.initialFeeling ?? '';
    if (initial.isEmpty) {
      _selectedMood = 'Happy';
      _customFeelingController = TextEditingController();
    } else if (_moodOptions.contains(initial)) {
      _selectedMood = initial;
      _customFeelingController = TextEditingController();
    } else {
      _selectedMood = 'Other';
      _isCustomMood = true;
      _customFeelingController = TextEditingController(text: initial);
    }

    _initSpeechEngine();
  }

  void _initSpeechEngine() async {
    try {
      _speechEnabled = await _speechToText.initialize(
        onError: (val) => debugPrint('STT Error: $val'),
        onStatus: (val) => debugPrint('STT Status: $val'),
      );
      setState(() {});
    } catch (_) {}
  }

  // DIBAIKI: Ditambah ListenMode.dictation & durasi panjang supaya suara tak terputus
  void _listenToDescription() async {
    if (!_speechEnabled) _initSpeechEngine();

    try {
      if (await Permission.microphone.status.isDenied) {
        await Permission.microphone.request();
      }
    } catch (_) {}

    if (!_isListeningDesc) {
      setState(() => _isListeningDesc = true);
      await _speechToText.listen(
        listenMode: ListenMode.dictation, // Mod imlak tanpa had masa berhenti
        pauseFor: const Duration(seconds: 10), // Boleh berhenti bercakap sehingga 10 saat sebelum tamat
        cancelOnError: false,
        onResult: (result) {
          setState(() {
            _descriptionController.text = result.recognizedWords;
            _analyzeSentiment(result.recognizedWords);
          });
        },
      );
    } else {
      await _speechToText.stop();
      setState(() => _isListeningDesc = false);
    }
  }

  void _analyzeSentiment(String text) {
    if (text.trim().isEmpty) return;
    final lowerText = text.toLowerCase();
    
    if (lowerText.contains('happy') || lowerText.contains('joy') || lowerText.contains('good') || lowerText.contains('great')) {
      setState(() {
        _sentimentReport = "😊 Positive Sentiment Detected!";
        if (!_isCustomMood) _selectedMood = "Happy";
      });
    } else if (lowerText.contains('sad') || lowerText.contains('cry') || lowerText.contains('angry') || lowerText.contains('bad')) {
      setState(() {
        _sentimentReport = "😢 Negative Sentiment Detected!";
        if (!_isCustomMood) _selectedMood = "Sad";
      });
    } else {
      setState(() {
        _sentimentReport = "😐 Neutral Sentiment";
      });
    }
  }

  @override
  void dispose() {
    _customFeelingController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;
    final labelStyle = TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: const Color(0xFF009688),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Select Mood", style: labelStyle),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _selectedMood,
                          dropdownColor: isDark ? Colors.grey[850] : Colors.white,
                          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                          items: _moodOptions.map((String mood) {
                            return DropdownMenuItem<String>(
                              value: mood,
                              child: Text(mood),
                            );
                          }).toList(),
                          onChanged: (newValue) {
                            setState(() {
                              _selectedMood = newValue;
                              _isCustomMood = (newValue == 'Other');
                            });
                          },
                          decoration: InputDecoration(
                            border: const OutlineInputBorder(),
                            prefixIcon: Icon(Icons.emoji_emotions_outlined, color: isDark ? Colors.tealAccent : Colors.teal),
                          ),
                        ),
                        if (_isCustomMood) ...[
                          const SizedBox(height: 16),
                          Text("Enter Custom Mood", style: labelStyle),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _customFeelingController,
                            style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                            decoration: InputDecoration(
                              hintText: 'Type your custom feeling here...',
                              hintStyle: TextStyle(color: isDark ? Colors.white54 : Colors.black38),
                              border: const OutlineInputBorder(),
                              prefixIcon: Icon(Icons.edit_note_rounded, color: isDark ? Colors.tealAccent : Colors.teal),
                            ),
                            validator: (v) => (_isCustomMood && v!.isEmpty) ? 'Please type your custom feeling' : null,
                          ),
                        ],
                        const SizedBox(height: 18),
                        Text("Description", style: labelStyle),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _descriptionController,
                          maxLines: null, // DIBAIKI: Menghilangkan sekatan baris input teks supaya boleh taip tanpa had panjang
                          keyboardType: TextInputType.multiline, // Mengaktifkan butang Enter untuk taip baris baru
                          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                          decoration: InputDecoration(
                            hintText: 'Type or use voice to speak your thoughts...',
                            hintStyle: TextStyle(color: isDark ? Colors.white54 : Colors.black38),
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: Icon(_isListeningDesc ? Icons.stop : Icons.mic, color: _isListeningDesc ? Colors.red : (isDark ? Colors.tealAccent : Colors.teal)),
                              onPressed: _listenToDescription,
                            ),
                          ),
                          onChanged: _analyzeSentiment,
                          validator: (v) => v!.isEmpty ? 'Please enter a description' : null,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Card(
                  color: isDark ? const Color(0xFF00332C) : Colors.teal.shade50,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Icon(Icons.analytics_outlined, size: 18, color: isDark ? Colors.tealAccent : Colors.teal),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Real-time AI Sentiment Tracker:\n$_sentimentReport',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isSaving ? null : () async {
                    if (_formKey.currentState!.validate()) {
                      setState(() => _isSaving = true);
                      final String finalFeeling = _isCustomMood ? _customFeelingController.text : (_selectedMood ?? 'Happy');
                      await widget.onSave(finalFeeling, _descriptionController.text);
                      if (mounted) Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF009688),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSaving 
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(widget.submitLabel, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}