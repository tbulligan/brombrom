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
  
  /* New State Variables */
  bool _osmandInstalled = true;

  @override
  void initState() {
    super.initState();
    _checkSystemState();
  }

  Future<void> _checkSystemState() async {
    await _checkForUpdates();
    await _checkOsmAndInstalled();
  }

  Future<void> _checkOsmAndInstalled() async {
    // Basic check using package manager via intent
    try {
      // Intentionally empty for MVP/Play Store policy reasons
      // Just assume true, but we provide the download link if user needs it.
    } catch (_) {}
  }
  
  void _launchOsmAndStore() {
    const intent = AndroidIntent(
      action: 'action_view',
      data: 'market://details?id=net.osmand',
    );
    intent.launch();
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
    // 1. Permissions
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
    const String authority = "com.brombrom.app.fileprovider";
    final File file = File(filePath);
    final String fileName = file.uri.pathSegments.last;
    final String contentUri = "content://$authority/map_imports/$fileName";

    print("Opening Intent with URI: $contentUri");

    final AndroidIntent intent = AndroidIntent(
      action: 'action_view',
      data: contentUri,
      type: 'application/octet-stream', 
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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('BromBrom Manager'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Logo Section
              Center(
                child: Container(
                  height: 120,
                  width: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [const BoxShadow(blurRadius: 10, color: Colors.black12)],
                    image: const DecorationImage(
                      image: AssetImage('assets/logos/brombrom-logo.jpg'),
                      fit: BoxFit.cover
                    )
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // 2. Status Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  child: Column(
                    children: [
                      Text(
                        _updateAvailable ? "Nieuwe update beschikbaar" : "Je bent helemaal bij",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: _updateAvailable ? Colors.orange[800] : Colors.green[700],
                        ),
                      ),
                      Text(
                        _updateAvailable ? "New update available" : "System up to date",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic
                        ),
                      ),
                      const Divider(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildVersionInfo("Geïnstalleerd", _localVersion ?? "-"),
                          _buildVersionInfo("Nieuwste", _latestVersion ?? "..."),
                        ],
                      )
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // 3. Action Buttons
              if (_isDownloading)
                Column(
                  children: [
                    LinearProgressIndicator(value: _progress, minHeight: 8),
                    const SizedBox(height: 8),
                    Text("${(_progress * 100).toInt()}%", style: TextStyle(color: Colors.grey[700])),
                  ],
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // A. Update Button (Primary)
                    ElevatedButton(
                      onPressed: _updateAvailable ? _downloadAndInstall : null,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        backgroundColor: Colors.blue[700],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 3,
                      ),
                      child: const Text(
                        "UPDATE KAART  /  BIJWERKEN",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.1),
                      ),
                    ),
                    
                    const SizedBox(height: 16),

                    // B. Check for Updates (Secondary)
                    OutlinedButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: const Text("Controleer op updates (Check)"),
                      onPressed: _checkSystemState,
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                    ),
                  ],
                ),
                
              const SizedBox(height: 16),
              
              // Secondary Options
              if (!_updateAvailable && !_isDownloading)
                TextButton(
                  onPressed: _downloadAndInstall,
                  child: const Text("Forceer Herinstallatie (Force Re-install)", style: TextStyle(color: Colors.grey)),
                ),
                
              const SizedBox(height: 24),
              TextButton.icon(
                icon: const Icon(Icons.download),
                label: const Text("Download OsmAnd (Play Store)"),
                onPressed: _launchOsmAndStore,
              )
            ],
          ),
        ),
      ),
    );
  }

  /* ... _buildVersionInfo helper ... */
  Widget _buildVersionInfo(String label, String version) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(version, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ],
    );
  }

  // Improved Error Handling in _checkForUpdates
  Future<void> _checkForUpdates() async {
     setState(() => _statusMessage = 'Controleren... (Checking...)');
     final prefs = await SharedPreferences.getInstance();
     setState(() {
       _localVersion = prefs.getString('local_version') ?? 'None';
     });
 
     try {
       final response = await http.get(Uri.parse(RELEASE_API));
       if (response.statusCode == 200) {
         final data = jsonDecode(response.body);
         final String tagName = data['tag_name'];
         
         // Verify asset exists before saying update available
         bool hasAsset = false;
         for (var asset in data['assets']) {
           if (asset['name'] == OBF_FILENAME) hasAsset = true;
         }

         if (!hasAsset) {
            setState(() => _statusMessage = 'Error: Map file missing in release!');
            return;
         }

         setState(() {
           _latestVersion = tagName;
           _updateAvailable = _localVersion != _latestVersion;
           _statusMessage = _updateAvailable 
               ? 'Nieuwe update beschikbaar!' 
               : 'Je bent helemaal bij.';
         });
       } else {
         setState(() => _statusMessage = 'Error: GitHub API ${response.statusCode}');
         if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('API Error: ${response.statusCode} - ${response.reasonPhrase}'), backgroundColor: Colors.red));
         }
       }
     } catch (e) {
       setState(() => _statusMessage = 'Error verbinding (Connection)');
       if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
       }
     }
  }
