// homepage_state.dart
part of 'homepage.dart';

class HomePageState extends State<HomePage> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  final TextEditingController _descCtrl = TextEditingController();
  String _selectedFeeling = "Happy";
  final List<String> _feelings = ["Happy", "Sad", "Angry", "Excited", "Amazed"];

  // ✅ Updated emojis for clearer distinction
  final Map<String, String> _feelingEmojis = {
    "Happy": "😊",
    "Sad": "😔",     // changed from 😢
    "Angry": "😡",   // changed from 😠
    "Excited": "🤩",
    "Amazed": "😲",
  };

  final Map<String, String> _feelingGifs = {
    "Happy": "assets/images/happy.gif",
    "Sad": "assets/images/sad.gif",
    "Angry": "assets/images/angry.gif",
    "Excited": "assets/images/excited.gif",
    "Amazed": "assets/images/amazed.gif",
  };

  String _temperature = "--°C";
  String _weatherIcon = "☀️";
  bool _isLoadingWeather = true;
  String _location = "Unknown";

  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _fetchWeather();
    _getLocation();
    _setupFCM();
  }

  // -------------------- FCM Setup --------------------
  void _setupFCM() async {
    final fcm = FirebaseMessaging.instance;
    NotificationSettings settings = await fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (settings.authorizationStatus != AuthorizationStatus.authorized) {
      print('Notifikasi tidak dibenarkan');
      return;
    }
    String? token = await fcm.getToken();
    print('FCM Token: $token');
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && token != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'fcmToken': token,
      }, SetOptions(merge: true));
    }

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message.notification?.body ?? 'Notifikasi baharu'),
            backgroundColor: Colors.teal,
          ),
        );
      }
    });
  }

  // -------------------- Location & Weather --------------------
  Future<void> _getLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _location = AppLocalizations.translate('location_disabled'));
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _location = AppLocalizations.translate('permission_denied'));
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() => _location = AppLocalizations.translate('permission_forever'));
        return;
      }
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );
      setState(() {
        _location = "${position.latitude.toStringAsFixed(2)}, ${position.longitude.toStringAsFixed(2)}";
      });
    } catch (e) {
      setState(() => _location = AppLocalizations.translate('unable_location'));
    }
  }

  Future<void> _fetchWeather() async {
    try {
      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best,
        );
      } catch (_) {}
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
          onLanguageChange: widget.onLanguageChange,
        ),
      ),
    );
  }

  // -------------------- Helper: GIF/Emoji --------------------
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

  // -------------------- CRUD Operations (with Trash) --------------------
  Future<void> _saveDiary() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    if (_descCtrl.text.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.translate('please_enter_description')),
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
        SnackBar(
          content: Text(AppLocalizations.translate('diary_saved')),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 1),
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

  // ✅ UPDATED: Removed undo action, shortened duration
  void _deleteDiary(String id, Map<String, dynamic> data) async {
    data['deletedAt'] = FieldValue.serverTimestamp();
    await FirebaseFirestore.instance.collection('deleted_diaries').doc(id).set(data);
    await FirebaseFirestore.instance.collection('diaries').doc(id).delete();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.translate('entry_deleted')),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _confirmDelete(String id, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.translate('delete_title')),
        content: Text(AppLocalizations.translate('delete_confirm')),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              AppLocalizations.translate('cancel'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
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
            child: Text(
              AppLocalizations.translate('yes'),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
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
          title: Text(AppLocalizations.translate('edit_diary')),
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
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: AppLocalizations.translate('feeling'),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                decoration: InputDecoration(
                  labelText: AppLocalizations.translate('description'),
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                ),
                maxLines: null,
                minLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(AppLocalizations.translate('cancel')),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF009688),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                if (descCtrl.text.trim().isEmpty) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(AppLocalizations.translate('please_enter_description')),
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
                  SnackBar(
                    content: Text(AppLocalizations.translate('entry_updated')),
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
              child: Text(
                AppLocalizations.translate('update'),
                style: const TextStyle(color: Colors.white),
              ),
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
        SnackBar(content: Text(AppLocalizations.translate('speech_unavailable'))),
      );
    }
  }

  void _stopVoiceSearch() {
    _speech.stop();
    if (mounted) setState(() => _isListening = false);
  }

  // -------------------- Statistik Mood --------------------
  void _showMoodStats() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('diaries')
          .where('userId', isEqualTo: user.uid)
          .get();
      final feelings = snapshot.docs.map((doc) => doc['feeling']?.toString() ?? 'Unknown').toList();
      if (feelings.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Tiada data statistik'), backgroundColor: Colors.grey),
          );
        }
        return;
      }
      final counts = <String, int>{};
      for (var f in feelings) {
        counts[f] = (counts[f] ?? 0) + 1;
      }
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(AppLocalizations.translate('mood_stats')),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: counts.entries.map((e) => 
                ListTile(
                  leading: _getFeelingWidget(e.key, size: 30),
                  title: Text('${e.key}: ${e.value}'),
                )
              ).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(_),
              child: Text(AppLocalizations.translate('ok')),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ralat: $e'), backgroundColor: Colors.red),
        );
      }
    }
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
                Text(
                  AppLocalizations.translate('app_title'),
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: Text(AppLocalizations.translate('profile')),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfilePage(
                    isDarkMode: widget.isDarkMode,
                    onToggleTheme: widget.onToggleTheme,
                    onLanguageChange: widget.onLanguageChange,
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: Text(AppLocalizations.translate('settings')),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SettingsPage(
                    isDarkMode: widget.isDarkMode,
                    onToggleTheme: widget.onToggleTheme,
                    onLanguageChange: widget.onLanguageChange,
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: Text(AppLocalizations.translate('trash')),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TrashPage(
                    isDarkMode: widget.isDarkMode,
                    onToggleTheme: widget.onToggleTheme,
                    onLanguageChange: widget.onLanguageChange,
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.bar_chart),
            title: Text(AppLocalizations.translate('mood_stats')),
            onTap: () {
              Navigator.pop(context);
              _showMoodStats();
            },
          ),
          ListTile(
            leading: const Icon(Icons.search),
            title: Text(AppLocalizations.translate('search_diary')),
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
            title: Text(AppLocalizations.translate('logout')),
            onTap: () {
              Navigator.pop(context);
              _handleLogout();
            },
          ),
          ListTile(
            leading: Icon(widget.isDarkMode ? Icons.light_mode : Icons.dark_mode),
            title: Text(widget.isDarkMode ? AppLocalizations.translate('light_mode') : AppLocalizations.translate('dark_mode')),
            onTap: () {
              Navigator.pop(context);
              _toggleTheme();
            },
          ),
        ],
      ),
    );
  }

  // -------------------- Format Date --------------------
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
                  hintText: AppLocalizations.translate('search_hint'),
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
              icon: const Icon(Icons.bar_chart),
              onPressed: _showMoodStats,
              color: Colors.white,
            ),
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
              tooltip: AppLocalizations.translate('logout'),
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
                Text(
                  AppLocalizations.translate('create_diary'),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: AppLocalizations.translate('how_feeling'),
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
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: AppLocalizations.translate('whats_mind'),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
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
                    child: Text(
                      AppLocalizations.translate('save_diary'),
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
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
                          AppLocalizations.translate('error_loading'),
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.book, size: 60, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          AppLocalizations.translate('no_entries'),
                          style: const TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppLocalizations.translate('start_writing'),
                          style: const TextStyle(fontSize: 14, color: Colors.grey),
                        ),
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
                  return Center(
                    child: Text(
                      AppLocalizations.translate('no_match'),
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
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
                                  tooltip: AppLocalizations.translate('edit_diary'),
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red.shade600, size: 22),
                                  onPressed: () => _confirmDelete(diary.id, data),
                                  tooltip: AppLocalizations.translate('delete_title'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(description, style: const TextStyle(fontSize: 14, height: 1.4)),
                            if (weather.isNotEmpty)
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
                                      Text(weather, style: const TextStyle(fontSize: 11)),
                                      if (location.isNotEmpty && 
                                          !location.contains('Unable') && 
                                          !location.contains('disabled') && 
                                          !location.contains('denied')) ...[
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