// homepage_state.dart
part of 'homepage.dart';

class HomePageState extends State<HomePage> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  final TextEditingController _descCtrl = TextEditingController();
  String _selectedFeeling = "Happy";
  final List<String> _feelings = ["Happy", "Sad", "Angry", "Excited", "Amazed"];
  
  // Weather variables
  String _weather = "Loading...";
  String _temperature = "--°C";
  String _weatherIcon = "☀️";
  bool _isLoadingWeather = true;

  // Feeling emoji map
  final Map<String, String> _feelingEmojis = {
    "Happy": "😊",
    "Sad": "😢",
    "Angry": "😡",
    "Excited": "🤩",
    "Amazed": "😲",
  };

  @override
  void initState() {
    super.initState();
    _fetchWeather();
  }

  Future<void> _fetchWeather() async {
    try {
      final response = await http.get(
        Uri.parse('https://api.open-meteo.com/v1/forecast?latitude=3.139&longitude=101.686&current_weather=true'),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final current = data['current_weather'];
        
        setState(() {
          _temperature = '${current['temperature'].toStringAsFixed(0)}°C';
          _weather = _getWeatherCondition(current['weathercode']);
          _weatherIcon = _getWeatherIcon(current['weathercode']);
          _isLoadingWeather = false;
        });
      }
    } catch (e) {
      setState(() {
        _weather = "Weather unavailable";
        _temperature = "--°C";
        _isLoadingWeather = false;
      });
    }
  }

  String _getWeatherCondition(int code) {
    if (code == 0) return 'Clear';
    if (code <= 3) return 'Partly Cloudy';
    if (code <= 49) return 'Foggy';
    if (code <= 69) return 'Rainy';
    if (code <= 79) return 'Snowy';
    if (code <= 99) return 'Thunderstorm';
    return 'Unknown';
  }

  String _getWeatherIcon(int code) {
    if (code == 0) return '☀️';
    if (code <= 3) return '⛅';
    if (code <= 49) return '🌫️';
    if (code <= 69) return '🌧️';
    if (code <= 79) return '❄️';
    if (code <= 99) return '⛈️';
    return '🌤️';
  }

  void _toggleTheme() {
    widget.onToggleTheme();
  }

  void _handleLogout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => LoginPage(
          isDarkMode: widget.isDarkMode,
          onToggleTheme: widget.onToggleTheme,
        ),
      ),
    );
  }

  String _getFeelingEmoji(String feeling) {
    return _feelingEmojis[feeling] ?? '😊';
  }

  Future<void> _saveDiary() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (_descCtrl.text.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a description")),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.collection("diaries").add({
        "userId": user.uid,
        "feeling": _selectedFeeling,
        "description": _descCtrl.text.trim(),
        "createdAt": FieldValue.serverTimestamp(),
      });

      _descCtrl.clear();
      setState(() {
        _selectedFeeling = "Happy";
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Diary saved successfully!")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error saving diary: $e")),
      );
    }
  }

  void _startVoiceSearch() async {
    bool available = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          if (mounted) {
            setState(() => _isListening = false);
          }
        }
      },
    );
    if (available) {
      if (mounted) {
        setState(() => _isListening = true);
      }
      _speech.listen(
        onResult: (result) {
          if (mounted) {
            setState(() {
              _descCtrl.text = result.recognizedWords;
            });
          }
        },
        listenOptions: stt.SpeechListenOptions(
          listenMode: stt.ListenMode.dictation,
          cancelOnError: true,
        ),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Speech recognition not available")),
      );
    }
  }

  void _stopVoiceSearch() {
    _speech.stop();
    if (mounted) {
      setState(() => _isListening = false);
    }
  }

  void _deleteDiary(String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: const Text("Are you sure you want to delete this entry?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final doc = FirebaseFirestore.instance.collection("diaries").doc(id);
              final snapshot = await doc.get();
              final data = snapshot.data();

              await doc.delete();

              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text("Entry deleted"),
                  action: SnackBarAction(
                    label: "Undo",
                    onPressed: () async {
                      if (data != null) {
                        await FirebaseFirestore.instance
                            .collection("diaries")
                            .add(data);
                      }
                    },
                  ),
                ),
              );
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  void _editDiary(String id, String oldFeeling, String oldDesc) {
    final TextEditingController feelingCtrl = TextEditingController(text: oldFeeling);
    final TextEditingController descCtrl = TextEditingController(text: oldDesc);

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text("Edit Diary Entry"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: oldFeeling,
                items: _feelings.map((f) {
                  return DropdownMenuItem(
                    value: f,
                    child: Row(
                      children: [
                        Text(_getFeelingEmoji(f)),
                        const SizedBox(width: 8),
                        Text(f),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  feelingCtrl.text = val!;
                },
                decoration: const InputDecoration(labelText: "Feeling"),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: "Description"),
                maxLines: null,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (descCtrl.text.trim().isEmpty) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Please enter a description")),
                  );
                  return;
                }
                await FirebaseFirestore.instance
                    .collection("diaries")
                    .doc(id)
                    .update({
                  "feeling": feelingCtrl.text,
                  "description": descCtrl.text.trim(),
                });
                Navigator.pop(ctx);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Entry updated successfully")),
                );
              },
              child: const Text("Update"),
            ),
          ],
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xFFE8F5E9),
      appBar: AppBar(
        title: Text(
          "${user?.email?.split('@')[0] ?? 'My'} Diary",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF009688),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Weather in AppBar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                if (!_isLoadingWeather) ...[
                  Text(
                    _weatherIcon,
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _temperature,
                    style: const TextStyle(fontSize: 14),
                  ),
                ] else ...[
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: _toggleTheme,
            color: Colors.white,
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Logout',
            onPressed: _handleLogout,
            color: Colors.white,
          ),
        ],
      ),
      body: Column(
        children: [
          // Create New Diary Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[900] : Colors.white,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 2,
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Create New Diary",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                // Feeling Dropdown with Emoji
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButtonFormField<String>(
                      value: _selectedFeeling,
                      items: _feelings.map((f) {
                        return DropdownMenuItem(
                          value: f,
                          child: Row(
                            children: [
                              Text(
                                _getFeelingEmoji(f),
                                style: const TextStyle(fontSize: 24),
                              ),
                              const SizedBox(width: 8),
                              Text(f),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() => _selectedFeeling = val!);
                      },
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: "Feeling",
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Description with Voice
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _descCtrl,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: "Description",
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                          ),
                          maxLines: null,
                          minLines: 2,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          _isListening ? Icons.stop : Icons.mic,
                          color: _isListening ? Colors.red : const Color(0xFF009688),
                        ),
                        onPressed: _isListening ? _stopVoiceSearch : _startVoiceSearch,
                        tooltip: _isListening ? "Stop" : "Voice input",
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Create Memo Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saveDiary,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF009688),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      "Create Memo",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Diary Entries List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("diaries")
                  .where("userId", isEqualTo: user?.uid)
                  .orderBy("createdAt", descending: true)
                  .snapshots(),
              builder: (ctx, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      "No diary entries yet",
                      style: TextStyle(fontSize: 16),
                    ),
                  );
                }

                final docs = snapshot.data!.docs;
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                  itemBuilder: (ctx, i) {
                    final diary = docs[i];
                    final feeling = diary["feeling"] ?? "Happy";
                    final description = diary["description"] ?? "";
                    final timestamp = diary["createdAt"] as Timestamp?;
                    final date = timestamp != null
                        ? timestamp.toDate()
                        : DateTime.now();

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[850] : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.05),
                            spreadRadius: 1,
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              // Feeling Emoji
                              Text(
                                _getFeelingEmoji(feeling),
                                style: const TextStyle(fontSize: 24),
                              ),
                              const SizedBox(width: 8),
                              // Feeling name
                              Text(
                                feeling,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              const Spacer(),
                              // Edit button
                              IconButton(
                                icon: const Icon(Icons.edit, size: 20),
                                onPressed: () => _editDiary(
                                  diary.id,
                                  feeling,
                                  description,
                                ),
                                color: Colors.blue.shade600,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                              const SizedBox(width: 8),
                              // Delete button
                              IconButton(
                                icon: const Icon(Icons.delete, size: 20),
                                onPressed: () => _deleteDiary(diary.id),
                                color: Colors.red.shade600,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          // Description
                          Text(
                            description,
                            style: const TextStyle(fontSize: 15),
                          ),
                          const SizedBox(height: 8),
                          // Date
                          Text(
                            _formatDate(date),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}