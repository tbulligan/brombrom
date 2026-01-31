import 'dart:convert';
import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';

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
  
  /* Diagnostic Logging */
  final List<String> _logs = [];
  void _log(String msg) {
    print(msg);
    setState(() {
      _logs.add("${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second} - $msg");
    });
  }

  @override
  void initState() {
    super.initState();
    _log("App Initialized");
    _checkSystemState();
  }

  Future<void> _checkSystemState() async {
    _log("Checking System State...");
    await _checkForUpdates();
  }
  
  void _launchOsmAndStore() {
    const intent = AndroidIntent(
      action: 'action_view',
      data: 'market://details?id=net.osmand',
    );
    intent.launch();
  }
  
  Future<void> _clearVersionCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('local_version');
    setState(() {
      _localVersion = 'None';
      _updateAvailable = true;
      _statusMessage = 'Cache Cleared. Update enabled.';
    });
    _log("Version Cache Cleared");
    _checkForUpdates();
  }

  Future<void> _checkForUpdates() async {
     _log("Starting Update Check...");
     setState(() => _statusMessage = 'Controleren... (Checking...)');
     
     final prefs = await SharedPreferences.getInstance();
     setState(() {
       _localVersion = prefs.getString('local_version') ?? 'None';
     });
     _log("Local Version: $_localVersion");
 
     try {
       final uri = Uri.parse(RELEASE_API);
       final response = await http.get(uri);
       
       if (response.statusCode == 200) {
         final data = jsonDecode(response.body);
         final String tagName = data['tag_name'];
         
         // Verify asset exists
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
               ? 'Update Available!' 
               : 'You are up to date.';
         });
       } else {
         setState(() => _statusMessage = 'GitHub API Error: ${response.statusCode}');
       }
     } catch (e) {
       _log("Only Check Error: $e");
       setState(() => _statusMessage = 'Connection Error / API Limit');
     }
  }

  Future<void> _downloadAndInstall() async {
    _log("Starting Download Sequence...");

    setState(() {
      _isDownloading = true;
      _statusMessage = 'Downloading Map...';
      _progress = 0.1;
    });

    try {
      // 2. Locate Download URL
      final response = await http.get(Uri.parse(RELEASE_API));
      final data = jsonDecode(response.body);
      
      String? mapUrl;
      for (var asset in data['assets']) {
        if (asset['name'] == OBF_FILENAME) {
          mapUrl = asset['browser_download_url'];
        }
      }

      if (mapUrl == null) throw Exception("Map file not found");
      _log("DL URL: $mapUrl");

      // 3. Download File
      final dir = await getExternalStorageDirectory(); 
      final String filePath = '${dir!.path}/$OBF_FILENAME';
      final File file = File(filePath);
      
      // Delete existing to allow clean download
      if (await file.exists()) {
        await file.delete();
      }

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
      _log("Download Complete.");

      // 4. Update Preferences
      if (_latestVersion != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('local_version', _latestVersion!);
          setState(() => _localVersion = _latestVersion);
      }
      
      setState(() {
         _isDownloading = false;
         _statusMessage = 'Opening Import Dialog...';
         _progress = 1.0;
         _updateAvailable = false;
      });

      // 5. Trigger Import in OsmAnd
      _openInOsmAnd(file.path);

    } catch (e) {
      _log("DL Error: $e");
      setState(() {
        _isDownloading = false;
        _statusMessage = 'Error: $e';
      });
    }
  }
  
  Future<void> _downloadRoutingXml() async {
     _log("Downloading Routing Style...");
     try {
       final response = await http.get(Uri.parse(RELEASE_API));
       final data = jsonDecode(response.body);
       String? xmlUrl;
       for (var asset in data['assets']) {
         if (asset['name'] == 'routing.xml') {
           xmlUrl = asset['browser_download_url'];
         }
       }
       
       if (xmlUrl == null) {
         _log("routing.xml not found");
         return;
       }

       final dir = await getExternalStorageDirectory(); 
       final File file = File('${dir!.path}/routing.xml');
       if (await file.exists()) await file.delete();

       final request = http.Request('GET', Uri.parse(xmlUrl));
       final streamedResponse = await request.send();
       
       final sink = file.openWrite();
       await streamedResponse.stream.listen((chunk) => sink.add(chunk)).asFuture();
       await sink.close();
       
       // Show Instructions
       if (mounted) {
         showDialog(
           context: context,
           builder: (ctx) => AlertDialog(
             title: const Text("Manual Action Required"),
             content: const Text(
               "Routing file downloaded.\n\n"
               "Open 'Files' app -> Move this file to:\n"
               "Android/data/net.osmand/files/routing/\n\n"
               "Note: If access is denied, use a PC or install a file manager like 'Solid Explorer'."
             ),
             actions: [
               TextButton(
                 onPressed: () {
                   Navigator.pop(ctx);
                   _shareFile(file.path, isXml: true);
                 },
                 child: const Text("Share File")
               ),
               TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Close")),
             ],
           )
         );
       }

     } catch (e) {
       _log("Routing DL Error: $e");
     }
  }

  Future<void> _openInOsmAnd(String filePath) async {
    const String authority = "com.brombrom.app.fileprovider";
    final File file = File(filePath);
    final String fileName = file.uri.pathSegments.last;
    final String contentUri = "content://$authority/map_imports_ext/$fileName";

    _log("Opening Intent...");

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
      _log("Intent Error: $e");
    }
  }

  Future<void> _shareFile(String filePath, {bool isXml = false}) async {
    final File file = File(filePath);
    if (!await file.exists()) return;

    try {
      final xFile = XFile(filePath);
      await Share.shareXFiles(
          [xFile], 
          text: isXml 
              ? 'Move to Android/data/net.osmand/files/routing/' 
              : 'Import into OsmAnd'
      );
    } catch (e) {
      _log("Share Error: $e");
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
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Card
            Card(
              color: Colors.white,
              child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        _updateAvailable ? "New Update Available" : "Up to Date",
                        style: TextStyle(
                            fontSize: 20, 
                            fontWeight: FontWeight.bold, 
                            color: _updateAvailable ? Colors.orange : Colors.green
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text("Installed: ${_localVersion ?? '-'}"),
                      Text("Latest: ${_latestVersion ?? '-'}"),
                      const SizedBox(height: 8),
                      TextButton(
                         onPressed: _clearVersionCache,
                         child: const Text("Reset Cache / Check Again", style: TextStyle(fontSize: 10, color: Colors.grey))
                      )
                    ],
                  ),
              ),
            ),
            const SizedBox(height: 24),
            
            if (_isDownloading)
               LinearProgressIndicator(value: _progress),
            
            if (!_isDownloading) ...[
                ElevatedButton(
                  onPressed: _downloadAndInstall,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    backgroundColor: _updateAvailable ? Colors.blue[800] : Colors.grey[700],
                    foregroundColor: Colors.white,
                  ),
                  child: Text(_updateAvailable ? "UPDATE MAP" : "RE-INSTALL MAP"),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    "⚠️ Tip: If OsmAnd fails to import, delete the old map in OsmAnd first.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.orange),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                OutlinedButton.icon(
                   icon: const Icon(Icons.alt_route),
                   label: const Text("Update Routing (XML)"),
                   onPressed: _downloadRoutingXml,
                ),
            ],
            
            const Spacer(),
            
            Container(
              height: 100,
              color: Colors.black12,
              child: ListView.builder(
                 itemCount: _logs.length,
                 itemBuilder: (ctx, i) => Text(_logs[i], style: const TextStyle(fontSize: 10)),
              ),
            )
          ],
        ),
      ),
    );
  }
}
