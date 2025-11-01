import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:video_player/video_player.dart';

class TranslationScreen extends StatefulWidget {
  const TranslationScreen({super.key});

  @override
  State<TranslationScreen> createState() => _TranslationScreenState();
}

class _TranslationScreenState extends State<TranslationScreen> {
  late stt.SpeechToText speech;
  final tts = FlutterTts();
  bool isListening = false;
  String transcription = "";
  String translatedText = "";
  String sourceLanguage = "English";
  String targetLanguage = "Hindi";

  // Language codes for translation
  final Map<String, String> languageCodes = {
    'English': 'en',
    'Hindi': 'hi',
    'Bengali': 'bn',
    'Telugu': 'te',
    'Marathi': 'mr',
    'Tamil': 'ta',
    'Gujarati': 'gu',
    'Kannada': 'kn',
    'Malayalam': 'ml',
    'Punjabi': 'pa',
  };

  // TTS language codes
  final Map<String, String> ttsLanguageCodes = {
    'English': 'en-IN',
    'Hindi': 'hi-IN',
    'Bengali': 'bn-IN',
    'Telugu': 'te-IN',
    'Marathi': 'mr-IN',
    'Tamil': 'ta-IN',
    'Gujarati': 'gu-IN',
    'Kannada': 'kn-IN',
    'Malayalam': 'ml-IN',
    'Punjabi': 'pa-IN',
  };

  // 🔵 Bluetooth variables
  List<ScanResult> scanResults = [];
  BluetoothDevice? connectedDevice;
  bool isScanning = false;
  bool isBluetoothConnected = false;

  // 🎥 Video player variable
  VideoPlayerController? _videoController;
  bool isVideoLoading = false;
  int translationCount = 0; // Track number of translations

  // 🐍 Flask API endpoint
  final String _flaskApiUrl = "http://192.168.0.105:5000/get_word"; // TODO: Replace with your PC's IP address
  Timer? _flaskTimer;


  // ✅ Google Translation API key - Add your key in .env file
  final String googleApiKey = 'AIzaSyC_yN-znlR42XiXaJHWzQEq9BLRZkVV5_c';
  final TextEditingController _inputController = TextEditingController();

  @override
  void initState() {
    super.initState();
    speech = stt.SpeechToText();
    _inputController.addListener(() {
      // Auto-translate when user types (optional - you can remove this)
      // translateText();
    });
    _checkBluetoothPermissions();
  }

  @override
  void dispose() {
    _inputController.dispose();
    tts.stop();
    _flaskTimer?.cancel();
    connectedDevice?.disconnect();
    _videoController?.dispose();
    super.dispose();
  }

  // 🐍 Fetch word from Flask API
  Future<void> _fetchWordFromFlask() async {
    if (!isBluetoothConnected) return; // Only fetch if connected

    try {
      final response = await http.get(Uri.parse(_flaskApiUrl));
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        final word = result['word'];

        if (word != null && word.isNotEmpty && _inputController.text != word) {
          setState(() {
            _inputController.text = word;
          });
          // Automatically trigger translation
          await translateText();
        }
      }
    } catch (e) {
      // Don't show snackbar for periodic polling, just log it
      print("🐍 Flask API error: $e");
    }
  }


  // 🔵 Check and request Bluetooth permissions
  Future<void> _checkBluetoothPermissions() async {
    if (Platform.isAndroid) {
      Map<Permission, PermissionStatus> statuses = await [
        Permission.bluetooth,
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.location,
      ].request();

      if (statuses.values.any((status) => !status.isGranted)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Bluetooth permissions are required"),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    }
  }

  // 🔵 Start Bluetooth scanning
  Future<void> startBluetoothScan() async {
    setState(() {
      isScanning = true;
      scanResults.clear();
    });

    try {
      // Start scanning
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));

      // Listen to scan results
      FlutterBluePlus.scanResults.listen((results) {
        if (mounted) {
          setState(() {
            scanResults = results;
          });
        }
      });

      // Wait for scan to complete
      await Future.delayed(const Duration(seconds: 10));
      await FlutterBluePlus.stopScan();

      if (mounted) {
        setState(() => isScanning = false);
        // Show available devices
        _showBluetoothDevicesDialog();
      }
    } catch (e) {
      if (mounted) {
        setState(() => isScanning = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Bluetooth scan error: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 🔵 Show Bluetooth devices dialog
  void _showBluetoothDevicesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Available Bluetooth Devices"),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: scanResults.isEmpty
              ? const Center(child: Text("No devices found"))
              : ListView.builder(
            itemCount: scanResults.length,
            itemBuilder: (context, index) {
              final result = scanResults[index];
              final deviceName = result.device.platformName.isEmpty
                  ? "Unknown Device"
                  : result.device.platformName;
              return ListTile(
                title: Text(deviceName),
                subtitle: Text(result.device.remoteId.toString()),
                trailing: Text("${result.rssi} dBm"),
                onTap: () {
                  Navigator.pop(context);
                  _connectToDevice(result.device);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
        ],
      ),
    );
  }

  // 🔵 Connect to Bluetooth device
  Future<void> _connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect(timeout: const Duration(seconds: 15));

      if (mounted) {
        setState(() {
          connectedDevice = device;
          isBluetoothConnected = true;
        });

        // Start polling Flask API
        _flaskTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
          _fetchWordFromFlask();
        });


        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Connected to ${device.platformName.isEmpty ? 'Device' : device.platformName}"),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Discover services (optional - for sending/receiving data)
      // List<BluetoothService> services = await device.discoverServices();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Connection failed: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 🔵 Disconnect Bluetooth device
  Future<void> _disconnectDevice() async {
    if (connectedDevice != null) {
      await connectedDevice!.disconnect();

      // Stop polling Flask API
      _flaskTimer?.cancel();


      if (mounted) {
        setState(() {
          connectedDevice = null;
          isBluetoothConnected = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Bluetooth disconnected"),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  // 🎥 Load and play video based on the translated word
  Future<void> _loadVideoForWord(String word) async {
    // Dispose previous video if exists
    if (_videoController != null) {
      await _videoController!.dispose();
      _videoController = null;
    }

    if (word.isEmpty) return;

    // Sanitize the word to create a valid filename
    final sanitizedWord = word.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    if (sanitizedWord.isEmpty) return;


    String videoPath = 'assets/videos/$sanitizedWord.mp4';

    setState(() {
      isVideoLoading = true;
    });

    try {
      _videoController = VideoPlayerController.asset(videoPath);
      await _videoController!.initialize();

      if (mounted) {
        setState(() {
          isVideoLoading = false;
        });

        // Auto play video
        _videoController!.play();
        _videoController!.setLooping(true);

        print('✅ Playing video for word: $word ($videoPath)');
      }
    } catch (e) {
      // Video not found
      if (mounted) {
        setState(() {
          isVideoLoading = false;
          _videoController = null;
        });
      }
      print('❌ Video not found for word: $word ($videoPath)');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sign video for "$word" not found.'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showLanguageSelectionDialog(bool isSourceLanguage) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isSourceLanguage ? "Select Source Language" : "Select Target Language"),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: ListView.builder(
            itemCount: languageCodes.length,
            itemBuilder: (context, index) {
              final language = languageCodes.keys.elementAt(index);
              final isSelected = isSourceLanguage
                  ? language == sourceLanguage
                  : language == targetLanguage;

              return ListTile(
                title: Text(
                  language,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? const Color(0xFF0D4D4D) : Colors.black87,
                  ),
                ),
                trailing: isSelected
                    ? const Icon(Icons.check, color: Color(0xFF0D4D4D))
                    : null,
                onTap: () {
                  setState(() {
                    if (isSourceLanguage) {
                      sourceLanguage = language;
                    } else {
                      targetLanguage = language;
                    }
                    // Clear previous translation when language changes
                    translatedText = "";
                  });
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
        ],
      ),
    );
  }

  // 🎙️ Start Listening
  Future<void> startListening() async {
    bool available = await speech.initialize();
    if (available) {
      setState(() => isListening = true);
      speech.listen(onResult: (result) {
        setState(() {
          _inputController.text = result.recognizedWords;
        });
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Speech recognition not available")),
      );
    }
  }

  // ⏹️ Stop Listening
  Future<void> stopListening() async {
    await speech.stop();
    setState(() => isListening = false);
  }

  // 🔊 Speak (Any Indian Language)
  Future<void> speak(String text, {String? languageCode}) async {
    if (text.trim().isEmpty) return;
    await tts.stop();

    // Use provided language code or target language
    String ttsCode = languageCode ?? ttsLanguageCodes[targetLanguage] ?? 'en-IN';

    await tts.setLanguage(ttsCode);
    await tts.setSpeechRate(0.9);
    await tts.setPitch(1.0);
    await tts.speak(text);
  }

  // 🌐 Translation API (with fallback to free API)
  Future<void> translateText() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter text to translate")),
      );
      return;
    }

    setState(() => translatedText = "Translating...");

    // Try Google API first, fallback to MyMemory API if key not available
    if (googleApiKey.isNotEmpty) {
      await _translateWithGoogle(text);
    } else {
      await _translateWithMyMemory(text);
    }
  }

  // Google Cloud Translation API
  Future<void> _translateWithGoogle(String text) async {
    final url = Uri.parse(
        'https://translation.googleapis.com/language/translate/v2?key=$googleApiKey');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'q': text,
          'source': languageCodes[sourceLanguage] ?? 'en',
          'target': languageCodes[targetLanguage] ?? 'hi',
          'format': 'text',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final translatedText = data['data']['translations'][0]['translatedText'];

        setState(() {
          this.translatedText = translatedText;
        });

        // Increment translation count
        translationCount++;

        await speak(translatedText);

        // Load video based on translation count
        await _loadVideoForWord(text);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Translation complete! 🎉"),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        // If Google API fails, try fallback
        await _translateWithMyMemory(text);
      }
    } catch (e) {
      // If error, try fallback
      await _translateWithMyMemory(text);
    }
  }

  // Free MyMemory Translation API (fallback)
  Future<void> _translateWithMyMemory(String text) async {
    final sourceLang = languageCodes[sourceLanguage] ?? 'en';
    final targetLang = languageCodes[targetLanguage] ?? 'hi';

    final url = Uri.parse(
        'https://api.mymemory.translated.net/get?q=${Uri.encodeComponent(text)}&langpair=$sourceLang|$targetLang');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final translatedText = data['responseData']['translatedText'];

        setState(() {
          this.translatedText = translatedText;
        });

        // Increment translation count
        translationCount++;

        await speak(translatedText);

        // Load video based on translation count
        await _loadVideoForWord(text);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Translation complete! 🎉"),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        setState(() => translatedText = "Translation failed ❌");

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Translation service unavailable"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() => translatedText = "Error: Unable to translate");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Network error: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Live Translation",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xFF0D4D4D),
        elevation: 0,
        actions: [
          // 🔵 Bluetooth button in AppBar
          IconButton(
            icon: Icon(
              isBluetoothConnected ? Icons.bluetooth_connected : Icons.bluetooth,
              color: isBluetoothConnected ? Colors.greenAccent : Colors.white,
            ),
            onPressed: () {
              if (isBluetoothConnected) {
                _disconnectDevice();
              } else {
                startBluetoothScan();
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Input Text Area with Mic Button
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D4D4D),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextField(
                        controller: _inputController,
                        maxLines: 5,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                        decoration: const InputDecoration(
                          hintText: "Enter text or connect to glove",
                          hintStyle: TextStyle(
                            color: Colors.white38,
                            fontSize: 16,
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: Icon(
                              isListening ? Icons.mic : Icons.mic_none,
                              color: isListening ? Colors.red : Colors.white,
                              size: 28,
                            ),
                            onPressed: () =>
                            isListening ? stopListening() : startListening(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Language Selection Row
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _showLanguageSelectionDialog(true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D4D4D),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  sourceLanguage,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.arrow_drop_down,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Swap Icon
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          final temp = sourceLanguage;
                          sourceLanguage = targetLanguage;
                          targetLanguage = temp;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.swap_horiz,
                          color: Color(0xFF0D4D4D),
                          size: 24,
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: GestureDetector(
                        onTap: () => _showLanguageSelectionDialog(false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D4D4D),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  targetLanguage,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.arrow_drop_down,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Translation Output Area
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color(0xFFD4E7E7),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.all(20),
                          child: Stack(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Translation",
                                    style: TextStyle(
                                      color: Color(0xFF0D4D4D),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    translatedText.isEmpty
                                        ? ""
                                        : translatedText,
                                    style: const TextStyle(
                                      color: Color(0xFF0D4D4D),
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 60),
                                ],
                              ),
                              // Speaker button positioned at bottom-right
                              if (translatedText.isNotEmpty &&
                                  translatedText != "Translating..." &&
                                  translatedText != "Translation failed ❌")
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0D4D4D),
                                      shape: BoxShape.circle,
                                    ),
                                    child: IconButton(
                                      icon: const Icon(
                                        Icons.volume_up,
                                        color: Colors.white,
                                        size: 28,
                                      ),
                                      onPressed: () => speak(translatedText),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),

                        // 🎥 Video Player Section
                        if (_videoController != null && _videoController!.value.isInitialized)
                          Padding(
                            padding: const EdgeInsets.only(top: 16.0),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: AspectRatio(
                                  aspectRatio: _videoController!.value.aspectRatio,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      VideoPlayer(_videoController!),
                                      // Play/Pause overlay
                                      GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            if (_videoController!.value.isPlaying) {
                                              _videoController!.pause();
                                            } else {
                                              _videoController!.play();
                                            }
                                          });
                                        },
                                        child: Container(
                                          color: Colors.transparent,
                                          child: Center(
                                            child: Icon(
                                              _videoController!.value.isPlaying
                                                  ? Icons.pause_circle_outline
                                                  : Icons.play_circle_outline,
                                              size: 64,
                                              color: Colors.white.withOpacity(0.8),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),

                        // Video loading indicator
                        if (isVideoLoading)
                          Padding(
                            padding: const EdgeInsets.only(top: 16.0),
                            child: Container(
                              height: 200,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircularProgressIndicator(
                                      color: Color(0xFF0D4D4D),
                                    ),
                                    SizedBox(height: 12),
                                    Text(
                                      "Loading video...",
                                      style: TextStyle(
                                        color: Color(0xFF0D4D4D),
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                        // Info text when no video available
                        if (translatedText.isNotEmpty &&
                            translatedText != "Translating..." &&
                            translatedText != "Translation failed ❌" &&
                            _videoController == null &&
                            !isVideoLoading)
                          Padding(
                            padding: const EdgeInsets.only(top: 16.0),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: Colors.grey[600],
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      "Sign language video not available for this translation",
                                      style: TextStyle(
                                        color: Colors.grey[700],
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Translate Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: translateText,
                    icon: const Icon(Icons.translate, color: Colors.white),
                    label: const Text(
                      'Translate',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D4D4D),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 🔵 Bluetooth scanning indicator
          if (isScanning)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      "Scanning for Bluetooth devices...",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
