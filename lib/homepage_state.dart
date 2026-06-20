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

  Color _moodCardColor(String? feeling) {
    final mood = feeling?.toLowerCase() ?? '';
    if (mood.contains('happy')) return const Color(0xFF64FFDA);
    if (mood.contains('sad')) return const Color(0xFFB2EBF2);
    if (mood.contains('angry')) return const Color(0xFFFFCDD2);
    return const Color(0xFF80DEEA);
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
          title: title,
          initialFeeling: initialFeeling,
          initialDescription: initialDescription,
          submitLabel: submitLabel,
          onSave: (feeling, description) async {
            if (id == null) {
              await SQLHelper.createDiary(feeling, description);
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

  Future<void> _deleteDiary(int id) async {
    final existingDiary = _diaries.firstWhere((element) => element['id'] == id);
    final backupFeeling = existingDiary['feeling'] ?? '';
    final backupDescription = existingDiary['description'] ?? '';

    await SQLHelper.deleteDiary(id);
    _refreshDiaries();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Diary entry deleted.'),
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'UNDO',
            textColor: Colors.tealAccent,
            onPressed: () async {
              await SQLHelper.createDiary(backupFeeling, backupDescription);
              _refreshDiaries();
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
        backgroundColor: const Color(0xFF009688),
        actions: [
          IconButton(
            icon: Icon(widget.isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: widget.onToggleTheme,
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
                          Text(_weatherSummary ?? 'Loading weather...'),
                          const SizedBox(height: 10),
                          Text('Suggested mood: ${_lastFeelingSuggestion ?? "Happy"}'),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _diaries.length,
                    itemBuilder: (context, index) {
                      final diary = _diaries[index];
                      return Card(
                        color: _moodCardColor(diary['feeling']),
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.white,
                            child: _moodAvatar(diary['feeling']),
                          ),
                          title: Text(diary['feeling'] ?? ''),
                          subtitle: Text(diary['description'] ?? ''),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(icon: const Icon(Icons.edit), onPressed: () => _showForm(diary['id'])),
                              IconButton(icon: const Icon(Icons.delete), onPressed: () => _deleteDiary(diary['id'])),
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
        child: const Icon(Icons.add),
      ),
    );
  }
}

// =========================================================================
// DIARY FORM PAGE (DROPDOWN + INTEGRATED VOICE INPUT)
// =========================================================================
class DiaryFormPage extends StatefulWidget {
  final String title;
  final String? initialFeeling;
  final String? initialDescription;
  final String submitLabel;
  final Future<void> Function(String feeling, String description) onSave;

  const DiaryFormPage({
    super.key,
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
                        const Text("Select Mood", style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _selectedMood,
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
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.emoji_emotions_outlined),
                          ),
                        ),
                        if (_isCustomMood) ...[
                          const SizedBox(height: 16),
                          const Text("Enter Custom Mood", style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _customFeelingController,
                            decoration: const InputDecoration(
                              hintText: 'Type your custom feeling here...',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.edit_note_rounded),
                            ),
                            validator: (v) => (_isCustomMood && v!.isEmpty) ? 'Please type your custom feeling' : null,
                          ),
                        ],
                        const SizedBox(height: 18),
                        const Text("Description", style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _descriptionController,
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText: 'Type or use voice to speak your thoughts...',
                            border: const OutlineInputBorder(),
                            suffixIcon: Padding(
                              padding: const EdgeInsets.only(bottom: 50),
                              child: IconButton(
                                icon: Icon(_isListeningDesc ? Icons.stop : Icons.mic, color: _isListeningDesc ? Colors.red : Colors.teal),
                                onPressed: _listenToDescription,
                              ),
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
                  color: Colors.teal.shade50,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        const Icon(Icons.analytics_outlined, size: 18, color: Colors.teal),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Real-time AI Sentiment Tracker:\n$_sentimentReport',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
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