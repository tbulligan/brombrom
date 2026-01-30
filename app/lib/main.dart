import 'dart:convert';
import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const BromBromApp());
}

class BromBromApp extends StatelessWidget {
  const BromBromApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BromBrom Installer',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const InstallerScreen(),
    );
  }
}

class InstallerScreen extends StatefulWidget {
  const InstallerScreen({super.key});

  @override
  State<InstallerScreen> createState() => _InstallerScreenState();
}

class _InstallerScreenState extends State<InstallerScreen> {
  String _statusMessage = 'Checking for updates...';
  bool _isDownloading = false;
  double _progress = 0.0;
  String? _latestVersion;
  String? _localVersion;
  bool _updateAvailable = false;
  
  // Constants
  static const String RELEASE_API = "https://api.github.com/repos/tbulligan/brombrom/releases/latest";
  static const String OBF_FILENAME = "NL_BromBrom_tagged.obf";
  static const String ROUTING_FILENAME = "routing.xml";

  @override
  void initState() {
    super.initState();
    _checkForUpdates();
  }

  Future<void> _checkForUpdates() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _localVersion = prefs.getString('local_version') ?? 'None';
    });

    try {
      final response = await http.get(Uri.parse(RELEASE_API));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final String tagName = data['tag_name'];
        
        setState(() {
          _latestVersion = tagName;
          _updateAvailable = _localVersion != _latestVersion;
          _statusMessage = _updateAvailable 
              ? 'New Update Available!' 
              : 'You are up to date.';
        });
      } else {
        setState(() => _statusMessage = 'Make sure you are online.');
      }
    } catch (e) {
      setState(() => _statusMessage = 'Error checking GitHub: $e');
    }
  }

  Future<void> _downloadAndInstall() async {
    // 1. Permissions (Android 11+ manages this via Scoped Storage usually, but good practice)
    if (await Permission.storage.request().isDenied) {
      setState(() => _statusMessage = 'Storage permission needed.');
      return;
    }

    setState(() {
      _isDownloading = true;
      _statusMessage = 'Downloading Map...';
      _progress = 0.1;
    });

    try {
      // 2. Locate Download URL
      final response = await http.get(Uri.parse(RELEASE_API));
      final data = jsonDecode(response.body);
      final List assets = data['assets'];
      
      String? mapUrl;
      for (var asset in assets) {
        if (asset['name'] == OBF_FILENAME) {
          mapUrl = asset['browser_download_url'];
        }
      }

      if (mapUrl == null) throw Exception("Map file not found in release!");

      // 3. Download File
      final dir = await getExternalStorageDirectory(); 
      // Note: On Android, getExternalStorageDirectory() returns a path in Android/data/com.brombrom.app/files
      // which is perfect for downloading and then sharing via FileProvider.
      
      final File file = File('${dir!.path}/$OBF_FILENAME');
      final request = http.Request('GET', Uri.parse(mapUrl));
      final streamedResponse = await request.send();

      final contentLength = streamedResponse.contentLength ?? 1;
      int received = 0;

      final sink = file.openWrite();
      await streamedResponse.stream.listen(
        (chunk) {
          sink.add(chunk);
          received += chunk.length;
          setState(() {
            _progress = received / contentLength;
          });
        },
      ).asFuture();
      await sink.close();

      // 4. Update Preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('local_version', _latestVersion!);
      setState(() {
         _localVersion = _latestVersion;
         _isDownloading = false;
         _statusMessage = 'Download Complete!';
         _progress = 1.0;
      });

      // 5. Trigger Import in OsmAnd
      _openInOsmAnd(file.path);

    } catch (e) {
      setState(() {
        _isDownloading = false;
        _statusMessage = 'Error: $e';
      });
    }
  }

  Future<void> _openInOsmAnd(String filePath) async {
    // Construct the Content URI for the FileProvider
    // Authority must match AndroidManifest.xml: ${applicationId}.fileprovider
    // default package is com.brombrom.app
    const String authority = "com.brombrom.app.fileprovider";
    
    // We need to map the raw file path to the path defined in file_paths.xml
    // Our file_paths.xml maps "." (root of external files) to "map_imports"
    // filePath is like: .../Android/data/com.brombrom.app/files/NL_BromBrom_tagged.obf
    final File file = File(filePath);
    final String fileName = file.uri.pathSegments.last;
    
    final String contentUri = "content://$authority/map_imports/$fileName";

    print("Opening Intent with URI: $contentUri");

    final AndroidIntent intent = AndroidIntent(
      action: 'action_view',
      data: contentUri,
      type: 'application/octet-stream', // Generic binary or OsmAnd specific
      flags: <int>[
        0x00000001, // FLAG_GRANT_READ_URI_PERMISSION
        0x10000000, // FLAG_ACTIVITY_NEW_TASK
      ],
    );
    
    try {
      await intent.launch();
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context, 
          builder: (ctx) => AlertDialog(
            title: const Text("Import Error"),
            content: Text("Could not launch OsmAnd automatically.\n\nFile location:\n$filePath"),
            actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("OK"))],
          )
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BromBrom Manager'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Card
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Icon(Icons.map, size: 48, color: Colors.blue),
                    const SizedBox(height: 16),
                    Text(
                      'Local Version: $_localVersion',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    Text(
                      'Latest Release: ${_latestVersion ?? "Checking..."}',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            
            // Status Text
            Text(
              _statusMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _updateAvailable ? Colors.orange[800] : Colors.green[700],
              ),
            ),
            const SizedBox(height: 24),

            // Download Button
            if (_isDownloading)
              LinearProgressIndicator(value: _progress, minHeight: 10)
            else
              ElevatedButton.icon(
                onPressed: _updateAvailable ? _downloadAndInstall : null,
                icon: const Icon(Icons.system_update),
                label: const Text("UPDATE MAP"),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 18),
                ),
              ),
              
            const SizedBox(height: 16),
            if (!_updateAvailable && !_isDownloading)
              OutlinedButton(
                onPressed: _downloadAndInstall,
                child: const Text("Force Re-install"),
              )
          ],
        ),
      ),
    );
  }
}
