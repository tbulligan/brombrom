import 'dart:convert';
import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart'; // Add to pubspec if missing, or use manual parsing
import 'package:permission_handler/permission_handler.dart';
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
  // CONFIG
  static const String RELEASE_API = "https://api.github.com/repos/tbulligan/brombrom/releases/latest";
  static const String OBF_FILENAME = "NL_BromBrom_tagged.obf";
  static const String XML_FILENAME = "routing.xml";
  static const String APK_FILENAME = "BromBrom.apk"; // Standard artifact name
  
  // PATHS (Public Downloads)
  final String _targetDir = "/storage/emulated/0/Download";
  
  // STATE
  bool _hasPermission = false;
  String _statusMessage = 'Checking permissions...';
  bool _isDownloading = false;
  double _progress = 0.0;
  
  // VERSION INFO
  DateTime? _latestReleaseDate;
  DateTime? _localMapDate;
  DateTime? _localRoutingDate;
  bool _mapUpdateAvailable = false;
  bool _routingUpdateAvailable = false;

  final List<String> _logs = [];
  void _log(String msg) {
    print(msg);
    setState(() {
      _logs.add("${DateFormat('HH:mm:ss').format(DateTime.now())} - $msg");
    });
  }

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    // Check MANAGE_EXTERNAL_STORAGE for Android 11+ functionality
    // This allows us to read/write Downloads freely and check timestamps
    var status = await Permission.manageExternalStorage.status;
    if (!status.isGranted) {
      setState(() {
         _hasPermission = false;
         _statusMessage = "Please grant 'All Files Access' to manage Downloads.";
      });
    } else {
      setState(() => _hasPermission = true);
      _checkVersions();
    }
  }

  Future<void> _requestPermission() async {
    await Permission.manageExternalStorage.request();
    _checkPermissions();
  }

  Future<void> _checkVersions() async {
    setState(() => _statusMessage = 'Checking GitHub & Local files...');
    
    try {
      // 1. Get GitHub Info
      final response = await http.get(Uri.parse(RELEASE_API));
      if (response.statusCode != 200) throw Exception("API Error ${response.statusCode}");
      
      final data = jsonDecode(response.body);
      final String publishedAt = data['published_at']; // "2025-01-30T10:00:00Z"
      _latestReleaseDate = DateTime.parse(publishedAt);
      
      _log("Latest Release: $_latestReleaseDate");

      // 2. Check Local Files
      final File mapFile = File('$_targetDir/$OBF_FILENAME');
      if (await mapFile.exists()) {
        _localMapDate = await mapFile.lastModified();
      } else {
        _localMapDate = null;
      }

      final File xmlFile = File('$_targetDir/$XML_FILENAME');
      if (await xmlFile.exists()) {
        _localRoutingDate = await xmlFile.lastModified();
      } else {
        _localRoutingDate = null;
      }
      
      // 3. Compare (If local is older than release OR missing, update needed)
      // Note: Download time is always > Release time, so simple logic:
      // If we downloaded AFTER the release date, we are good.
      // If Local Date < Release Date, then new release came out after we downloaded.
      
      _mapUpdateAvailable = _localMapDate == null || _localMapDate!.isBefore(_latestReleaseDate!);
      _routingUpdateAvailable = _localRoutingDate == null || _localRoutingDate!.isBefore(_latestReleaseDate!);

      setState(() {
        _statusMessage = (_mapUpdateAvailable || _routingUpdateAvailable) 
            ? "Updates Available!" 
            : "Files in Downloads are up to date.";
      });

    } catch (e) {
      _log("Check Error: $e");
      setState(() => _statusMessage = "Connection/API Error");
    }
  }

  Future<void> _downloadFile(String fileName, {bool isMap = true}) async {
    setState(() {
      _isDownloading = true;
      _statusMessage = "Downloading $fileName...";
      _progress = 0.0;
    });

    try {
      // 1. Get URL
      final response = await http.get(Uri.parse(RELEASE_API));
      final data = jsonDecode(response.body);
      String? dlUrl;
      for (var asset in data['assets']) {
        if (asset['name'] == fileName) dlUrl = asset['browser_download_url'];
      }
      if (dlUrl == null) throw Exception("File not found in release");

      // 2. Download to Public Downloads
      final File file = File('$_targetDir/$fileName');
      if (await file.exists()) await file.delete();

      _log("DL Start: $dlUrl");
      
      // Use Client to handle potential redirects manually if needed, or set headers
      final client = http.Client();
      var request = http.Request('GET', Uri.parse(dlUrl!));
      request.headers['User-Agent'] = 'BromBromApp/1.0';
      request.followRedirects = true; // Ensure redirects are followed
      
      final streamedResponse = await client.send(request);
      
      if (streamedResponse.statusCode != 200) {
         // Read error
         final body = await streamedResponse.stream.bytesToString();
         throw Exception("HTTP ${streamedResponse.statusCode}: $body");
      }

      final contentLength = streamedResponse.contentLength ?? 1;
      int received = 0;
      
      final sink = file.openWrite();
      await streamedResponse.stream.listen((chunk) {
        sink.add(chunk);
        received += chunk.length;
        setState(() => _progress = received / contentLength);
      }).asFuture();
      await sink.close();
      client.close();
      
      // 3. Post-Download: Media Scan
      _log("Saved: ${file.path} ($received bytes)");
      if (received < 1000) {
        _log("WARNING: File is tiny! Check GitHub Assets.");
      }
      _scanFile(file.path);
      
      // Update check state immediately
      await _checkVersions();

      setState(() {
        _isDownloading = false;
        _progress = 1.0;
        _statusMessage = "Download Complete!";
      });

      // 4. Trigger Handoff
      if (fileName.endsWith(".apk")) { // APP UPDATE
        _installApk(file.path);
      } else if (isMap) {
        _openMapInOsmAnd(file.path);
      } else {
        _showRoutingInstructions(file.path);
      }

    } catch (e) {
      _log("DL Error: $e");
      setState(() {
        _isDownloading = false;
        _statusMessage = "Error: $e";
      });
    }
  }
  
  void _scanFile(String path) {
    // Notify MediaScanner so it shows up in Google Files
    try {
      final AndroidIntent intent = AndroidIntent(
        action: 'android.intent.action.MEDIA_SCANNER_SCAN_FILE',
        data: Uri.parse("file://$path").toString(),
      );
      intent.launch();
    } catch (e) {
      _log("Scan Error: $e");
    }
  }

  Future<void> _openMapInOsmAnd(String path) async {
    // Open using View Intent with FileProvider URI
    // Path: /storage/emulated/0/Download/filename.obf
    // XML: <external-path name="external_files" path="." />
    // URI: content://com.brombrom.app.fileprovider/external_files/Download/filename.obf
    
    final fileName = path.split('/').last;
    final contentUri = "content://com.brombrom.app.fileprovider/external_files/Download/$fileName";
    
    _log("Opening Intent: $contentUri");

    try {
      final AndroidIntent intent = AndroidIntent(
        action: 'action_view',
        data: contentUri,
        type: 'application/octet-stream',
        flags: <int>[
          0x00000001, // FLAG_GRANT_READ_URI_PERMISSION
          0x10000000, // FLAG_ACTIVITY_NEW_TASK
        ],
      );
      await intent.launch();
    } catch (e) {
      _log("Launch Error: $e. Using Share Sheet.");
      _shareFile(path);
    }
  }
  
  Future<void> _installApk(String path) async {
    // Trigger APK install
    final fileName = path.split('/').last;
    final contentUri = "content://com.brombrom.app.fileprovider/external_files/Download/$fileName";
    
    _log("Installing APK: $contentUri");
    
    try {
       final AndroidIntent intent = AndroidIntent(
        action: 'action_view',
        data: contentUri,
        type: 'application/vnd.android.package-archive',
        flags: <int>[
          0x00000001, // FLAG_GRANT_READ_URI_PERMISSION
          0x10000000, // FLAG_ACTIVITY_NEW_TASK
        ],
      );
      await intent.launch();
    } catch (e) {
      _log("Install Error: $e");
      // Fallback?
    }
  }

  void _showRoutingInstructions(String path) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Routing File Downloaded"),
        content: const Text(
          "File saved to 'Downloads'.\n\n"
          "HOW TO INSTALL:\n"
          "1. Open OsmAnd and ensure you have a BromBrom profile (if not: Settings → App Profiles → New → Driving → BromBrom).\n"
          "2. Select your BromBrom profile.\n"
          "3. Go to Navigation Settings → Navigation Type.\n"
          "4. Tap 'Import routing file' and select 'routing.xml' from Downloads.\n"
          "5. If prompted, choose Replace to update the existing version.\n"
          "6. Ensure BromBrom is selected as the active type."
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("OK")),
        ],
      )
    );
  }
  
  Future<void> _shareFile(String path) async {
    final xFile = XFile(path);
    await Share.shareXFiles([xFile]);
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasPermission) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.folder_shared, size: 64, color: Colors.blue),
                const SizedBox(height: 24),
                const Text(
                  "Access Required",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                const Text(
                  "To download files to your Downloads folder and check versions, we need 'All Files Access'.",
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _requestPermission,
                  child: const Text("ALLOW ACCESS"),
                )
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
          title: const Text("BromBrom Manager"), 
          backgroundColor: Colors.blue[800], 
          foregroundColor: Colors.white,
          actions: [
             IconButton(
               icon: const Icon(Icons.system_update),
               tooltip: "Update App",
               onPressed: () => _downloadFile(APK_FILENAME, isMap: false),
             )
          ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // STATUS
            // STATUS
            Card(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    if (!_mapUpdateAvailable && !_routingUpdateAvailable)
                       const Row(
                         mainAxisAlignment: MainAxisAlignment.center,
                         children: [
                           Icon(Icons.check_circle, color: Colors.green),
                           SizedBox(width: 8),
                           Expanded(child: Text("BromBrom files in Download are up to date", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green))),
                         ],
                       )
                    else 
                       Text(_statusMessage, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),

                    const SizedBox(height: 8),
                    if (_latestReleaseDate != null)
                      Text("Latest Release: ${DateFormat('yyyy-MM-dd HH:mm').format(_latestReleaseDate!)}"),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            
            // DOWNLOADERS
            if (_isDownloading) ...[
               LinearProgressIndicator(value: _progress),
               Padding(
                 padding: const EdgeInsets.only(top: 8.0),
                 child: Text("${(_progress * 100).toStringAsFixed(1)}%", textAlign: TextAlign.center),
               )
            ],

            if (!_isDownloading) ...[
                // MAP
                ElevatedButton(
                  onPressed: () => _downloadFile(OBF_FILENAME, isMap: true),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    // User requested Orange for Update
                    backgroundColor: _mapUpdateAvailable ? Colors.orange[800] : Colors.grey[300],
                    foregroundColor: _mapUpdateAvailable ? Colors.white : Colors.black87,
                  ),
                  child: Column(
                    children: [
                      Text(_mapUpdateAvailable ? "UPDATE MAP" : "RE-DOWNLOAD MAP"),
                      if (_localMapDate != null)
                        Text("On disk: ${(_localMapDate!.isBefore(_latestReleaseDate ?? DateTime(0))) ? 'Old Version' : 'Current'}", style: TextStyle(fontSize: 10, color: _mapUpdateAvailable ? Colors.white70 : Colors.black54)),
                    ],
                  ),
                ),
                // Show tip always for Map action
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    "⚠️ Tip: If import fails, delete the old map in OsmAnd first.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.orange, fontStyle: FontStyle.italic, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // ROUTING
                ElevatedButton(
                  onPressed: () => _downloadFile(XML_FILENAME, isMap: false),
                   style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    backgroundColor: _routingUpdateAvailable ? Colors.orange[800] : Colors.grey[300],
                    foregroundColor: _routingUpdateAvailable ? Colors.white : Colors.black87,
                  ),
                  child: Text(_routingUpdateAvailable ? "UPDATE BromBrom Routing" : "RE-DOWNLOAD Routing"),
                ),
                
                // Only show essential warning if update available or first install (local is null)
                if (_routingUpdateAvailable || _localRoutingDate == null)
                  Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            "Essential for correct navigation logic!",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.red[800], fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                  ),
            ],
            
            const Spacer(),
            // LOGS
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
      )
    );
  }
}
