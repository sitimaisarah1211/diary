// homepage_state.dart
part of 'homepage.dart';

class HomePageState extends State<HomePage> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  final TextEditingController _descCtrl = TextEditingController();
  String _selectedFeeling = "Happy";
  final List<String> _feelings = ["Happy", "Sad", "Angry", "Excited", "Amazed"];

  // Fallback emojis
  final Map<String, String> _feelingEmojis = {
    "Happy": "😊",
    "Sad": "😢",
    "Angry": "😡",
    "Excited": "🤩",
    "Amazed": "😲",
  };

  // GIF asset paths
  final Map<String, String> _feelingGifs = {
    "Happy": "assets/images/happy.gif",
    "Sad": "assets/images/sad.gif",
    "Angry": "assets/images/angry.gif",
    "Excited": "assets/images/excited.gif",
    "Amazed": "assets/images/amazed.gif",
  };

  // Weather & Location
  String _temperature = "--°C";
  String _weatherIcon = "☀️";
  bool _isLoadingWeather = true;
  String _location = "Unknown";

  // Search
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _fetchWeather();
    _getLocation();
  }

  // -------------------- Location & Weather --------------------
  Future<void> _getLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _location = "Location disabled");
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _location = "Permission denied");
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() => _location = "Permission denied forever");
        return;
      }
      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _location = "${position.latitude.toStringAsFixed(2)}, ${position.longitude.toStringAsFixed(2)}";
      });
    } catch (e) {
      setState(() => _location = "Unable to get location");
    }
  }

  Future<void> _fetchWeather() async {
    try {
      Position? position;
      try {
        position = await Geolocator.getCurrentPosition();
      } catch (e) {}
      String url;
      if (position != null) {
        url = 'https://api.open-meteo.com/v1/forecast?latitude=${position.latitude}&longitude=${position.longitude}&current_weather=true';
      } else {
        url = 'https://api.open-meteo.com/v1/forecast?latitude=3.139&longitude=101.686&current_weather=true';
      }
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final current = data['current_weather'];
        setState(() {
          _temperature = '${current['temperature'].toStringAsFixed(0)}°C';
          _weatherIcon = _getWeatherIcon(current['weathercode']);
          _isLoadingWeather = false;
        });
      }
    } catch (e) {
      setState(() {
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

  // -------------------- Theme & Logout --------------------
  void _toggleTheme() => widget.onToggleTheme();

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

  // -------------------- Helper: GIF or Emoji --------------------
  Widget _getFeelingWidget(String feeling, {double size = 60}) {
    final assetPath = _feelingGifs[feeling];
    if (assetPath != null) {
      return Image.asset(
        assetPath,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (ctx, error, stack) {
          return Text(
            _feelingEmojis[feeling] ?? '😊',
            style: TextStyle(fontSize: size),
          );
        },
      );
    } else {
      return Text(
        _feelingEmojis[feeling] ?? '😊',
        style: TextStyle(fontSize: size),
      );
    }
  }

  // -------------------- CRUD Operations --------------------
  Future<void> _saveDiary() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    if (_descCtrl.text.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter a description"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    try {
      await FirebaseFirestore.instance.collection("diaries").add({
        "userId": user.uid,
        "feeling": _selectedFeeling,
        "description": _descCtrl.text.trim(),
        "createdAt": FieldValue.serverTimestamp(),
        "location": _location,
        "weather": "$_weatherIcon $_temperature",
      });
      _descCtrl.clear();
      setState(() => _selectedFeeling = "Happy");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✨ Diary saved successfully!"),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 1),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _confirmDelete(String id, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("🗑️ Delete Entry"),
        content: const Text("Are you sure you want to delete this diary entry?"),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("No", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _deleteDiary(id, data);
            },
            child: const Text("Yes", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _deleteDiary(String id, Map<String, dynamic> data) {
    FirebaseFirestore.instance.collection("diaries").doc(id).delete();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("🗑️ Entry deleted"),
        backgroundColor: Colors.red.shade700,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: "UNDO",
          textColor: Colors.white,
          onPressed: () async {
            await FirebaseFirestore.instance.collection("diaries").add(data);
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("✅ Entry restored!"),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 1),
              ),
            );
          },
        ),
      ),
    );
  }

  void _editDiary(String id, String oldFeeling, String oldDesc) {
    String newFeeling = oldFeeling;
    final TextEditingController descCtrl = TextEditingController(text: oldDesc);
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text("✏️ Edit Diary"),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButtonFormField<String>(
                    value: newFeeling,
                    items: _feelings.map((f) {
                      return DropdownMenuItem(
                        value: f,
                        child: Row(
                          children: [
                            _getFeelingWidget(f, size: 32),
                            const SizedBox(width: 8),
                            Text(f),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) => newFeeling = val!,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: "Feeling",
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(
                  labelText: "Description",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                ),
                maxLines: null,
                minLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF009688),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                if (descCtrl.text.trim().isEmpty) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Please enter a description"),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }
                await FirebaseFirestore.instance
                    .collection("diaries")
                    .doc(id)
                    .update({
                  "feeling": newFeeling,
                  "description": descCtrl.text.trim(),
                });
                Navigator.pop(ctx);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("✅ Entry updated!"),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 1),
                  ),
                );
              },
              child: const Text("Update", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  // -------------------- Voice Input --------------------
  void _startVoiceSearch() async {
    bool available = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          if (mounted) setState(() => _isListening = false);
        }
      },
    );
    if (available) {
      if (mounted) setState(() => _isListening = true);
      _speech.listen(
        onResult: (result) {
          if (mounted) setState(() => _descCtrl.text = result.recognizedWords);
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
    if (mounted) setState(() => _isListening = false);
  }

  // -------------------- Build Drawer --------------------
  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFF009688)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  FirebaseAuth.instance.currentUser?.email ?? 'User',
                  style: const TextStyle(color: Colors.white, fontSize: 20),
                ),
                const Text(
                  'My Diary',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profile'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfilePage(
                    isDarkMode: widget.isDarkMode,
                    onToggleTheme: widget.onToggleTheme,
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SettingsPage(
                    isDarkMode: widget.isDarkMode,
                    onToggleTheme: widget.onToggleTheme,
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.search),
            title: const Text('Search Diary'),
            onTap: () {
              Navigator.pop(context);
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchQuery = '';
                  _searchCtrl.clear();
                }
              });
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () {
              Navigator.pop(context);
              _handleLogout();
            },
          ),
          ListTile(
            leading: Icon(widget.isDarkMode ? Icons.light_mode : Icons.dark_mode),
            title: Text(widget.isDarkMode ? 'Light Mode' : 'Dark Mode'),
            onTap: () {
              Navigator.pop(context);
              _toggleTheme();
            },
          ),
        ],
      ),
    );
  }

  // -------------------- Date Format --------------------
  String _formatDate(DateTime date) => DateFormat('dd MMM yyyy, HH:mm').format(date);

  // -------------------- Build --------------------
  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      drawer: _buildDrawer(),
      backgroundColor: isDark ? Colors.black : const Color(0xFFE8F5E9),
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchCtrl,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search diary...',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.search, color: Colors.white),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.close, color: Colors.white),
                    onPressed: () {
                      setState(() {
                        _isSearching = false;
                        _searchQuery = '';
                        _searchCtrl.clear();
                      });
                    },
                  ),
                ),
                style: const TextStyle(color: Colors.white),
                onChanged: (value) => setState(() => _searchQuery = value),
              )
            : Text(
                "${user?.email?.split('@')[0] ?? 'My'} Diary",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
        backgroundColor: const Color(0xFF009688),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (!_isLoadingWeather) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  Text(_weatherIcon, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 4),
                  Text(_temperature, style: const TextStyle(fontSize: 13)),
                ],
              ),
            ),
          ],
          if (!_isSearching) ...[
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () => setState(() => _isSearching = true),
              color: Colors.white,
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
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButtonFormField<String>(
                      value: _selectedFeeling,
                      items: _feelings.map((f) {
                        return DropdownMenuItem(
                          value: f,
                          child: Row(
                            children: [
                              _getFeelingWidget(f, size: 32),
                              const SizedBox(width: 8),
                              Text(f),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedFeeling = val!),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: "How are you feeling?",
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Center(child: _getFeelingWidget(_selectedFeeling, size: 80)),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _descCtrl,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: "What's on your mind?",
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
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
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saveDiary,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF009688),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      "💾 Save Diary",
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
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
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF009688)),
                  );
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 60, color: Colors.red.shade300),
                        const SizedBox(height: 16),
                        Text(
                          "Error loading entries",
                          style: TextStyle(color: Colors.grey.shade600),
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
                        Icon(Icons.book, size: 60, color: Colors.grey),
                        SizedBox(height: 16),
                        Text("No diary entries yet", style: TextStyle(fontSize: 16, color: Colors.grey)),
                        SizedBox(height: 8),
                        Text("Start writing your first entry above ✨", style: TextStyle(fontSize: 14, color: Colors.grey)),
                      ],
                    ),
                  );
                }

                final docs = snapshot.data!.docs;
                final filteredDocs = _searchQuery.isEmpty
                    ? docs
                    : docs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final desc = data['description']?.toString() ?? '';
                        final feeling = data['feeling']?.toString() ?? '';
                        return desc.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                            feeling.toLowerCase().contains(_searchQuery.toLowerCase());
                      }).toList();

                if (filteredDocs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No entries match your search',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => setState(() {}),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: filteredDocs.length,
                    itemBuilder: (ctx, i) {
                      final diary = filteredDocs[i];
                      final data = diary.data() as Map<String, dynamic>;
                      final feeling = data['feeling']?.toString() ?? "Happy";
                      final description = data['description']?.toString() ?? "";
                      final timestamp = data['createdAt'] as Timestamp?;
                      final date = timestamp != null ? timestamp.toDate() : DateTime.now();
                      final location = data['location']?.toString() ?? "";
                      final weather = data['weather']?.toString() ?? "";

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[850] : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.08),
                              spreadRadius: 1,
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                _getFeelingWidget(feeling, size: 30),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        feeling,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                      Text(
                                        _formatDate(date),
                                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.edit, color: Colors.blue.shade600, size: 22),
                                  onPressed: () => _editDiary(diary.id, feeling, description),
                                  tooltip: 'Edit',
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red.shade600, size: 22),
                                  onPressed: () => _confirmDelete(diary.id, data),
                                  tooltip: 'Delete',
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(description, style: const TextStyle(fontSize: 14, height: 1.4)),
                            if (location.isNotEmpty || weather.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF009688).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (weather.isNotEmpty)
                                        Text(weather, style: const TextStyle(fontSize: 11)),
                                      if (location.isNotEmpty) ...[
                                        const SizedBox(width: 4),
                                        Icon(Icons.location_on, size: 12, color: Colors.grey.shade600),
                                        Text(location, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}