import 'dart:convert';
import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For MethodChannel
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
  // Method Channel for SAF
  static const platform = MethodChannel('com.brombrom.app/saf');

  String _statusMessage = 'Checking configuration...';
  bool _isDownloading = false;
  double _progress = 0.0;
  String? _latestVersion;
  String? _localVersion;
  bool _updateAvailable = false;
  String? _safUri; // The persistent URI for OsmAnd folder
  
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
    _checkSystemState();
  }

  Future<void> _checkSystemState() async {
    _log("Checking System State...");
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _safUri = prefs.getString('saf_tree_uri');
    });
    
    if (_safUri != null) {
      _log("SAF Permission: GRANTED ($_safUri)");
      await _checkForUpdates();
    } else {
      _log("SAF Permission: MISSING");
      setState(() => _statusMessage = "Setup Required: Grant Access to OsmAnd");
    }
  }

  Future<void> _requestSafPermission() async {
    try {
      _log("Requesting Folder Access...");
      final String uri = await platform.invokeMethod('requestOsmandAccess');
      _log("Got URI: $uri");
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('saf_tree_uri', uri);
      
      setState(() {
        _safUri = uri;
        _statusMessage = "Access Granted! Checking updates...";
      });
      
      await _checkForUpdates();
      
    } catch (e) {
      _log("SAF ERROR: $e");
      setState(() => _statusMessage = "Error: Access Denied or Canceled");
    }
  }

  Future<void> _checkForUpdates() async {
     setState(() => _statusMessage = 'Checking updates...');
     final prefs = await SharedPreferences.getInstance();
     setState(() => _localVersion = prefs.getString('local_version') ?? 'None');
 
     try {
       final response = await http.get(Uri.parse(RELEASE_API));
       if (response.statusCode == 200) {
         final data = jsonDecode(response.body);
         final String tagName = data['tag_name'];
         
         bool hasAsset = data['assets'].any((a) => a['name'] == OBF_FILENAME);
         if (!hasAsset) {
            setState(() => _statusMessage = 'Error: Map missing in release!');
            return;
         }

         setState(() {
           _latestVersion = tagName;
           _updateAvailable = _localVersion != _latestVersion;
           _statusMessage = _updateAvailable 
               ? 'Update Available!' 
               : 'Up to Date (Je bent helemaal bij)';
         });
       } else {
         setState(() => _statusMessage = 'GitHub API Error: ${response.statusCode}');
       }
     } catch (e) {
       setState(() => _statusMessage = 'Connection Error');
     }
  }

  Future<void> _downloadAndInstall(String assetName, {bool isRouting = false}) async {
    setState(() {
      _isDownloading = true;
      _statusMessage = 'Downloading $assetName...';
      _progress = 0.1;
    });

    try {
      // 1. Get URL
      final response = await http.get(Uri.parse(RELEASE_API));
      final data = jsonDecode(response.body);
      String? dlUrl;
      for (var asset in data['assets']) {
        if (asset['name'] == assetName) {
          dlUrl = asset['browser_download_url'];
        }
      }
      if (dlUrl == null) throw Exception("Asset not found");

      // 2. Download to CACHE (Temp)
      final tempDir = await getTemporaryDirectory();
      final File tempFile = File('${tempDir.path}/$assetName');
      if (await tempFile.exists()) await tempFile.delete();

      _log("Downloading to Temp: ${tempFile.path}");
      
      final request = http.Request('GET', Uri.parse(dlUrl));
      final streamedResponse = await request.send();
      final contentLength = streamedResponse.contentLength ?? 1;
      int received = 0;
      final sink = tempFile.openWrite();
      
      await streamedResponse.stream.listen((chunk) {
          sink.add(chunk);
          received += chunk.length;
          setState(() => _progress = received / contentLength);
      }).asFuture();
      await sink.close();
      
      // 3. COPY TO OSMAND via SAF
      setState(() => _statusMessage = 'Installing to OsmAnd...');
      _log("Invoking Native Copy...");
      
      // For routing.xml, we usually want it in 'routing/' subfolder, but 
      // simple SAF usually grants access to 'files/'. 
      // If user selected 'files', we can write 'routing.xml' to root of files.
      // OsmAnd routing folder is files/routing/ ?
      // If the user selected 'files', we might not be able to write to 'routing/' subfolder easily 
      // unless we recreate document file tree logic.
      // SIMPLE FIX: Just write to the root of the selected folder.
      
      final bool success = await platform.invokeMethod('copyFileToSaf', {
        'srcPath': tempFile.path,
        'destFilename': assetName,
        'treeUri': _safUri,
        'mimeType': isRouting ? 'text/xml' : 'application/octet-stream'
      });

      if (success) {
        _log("Native Copy Success!");
        if (!isRouting) {
           final prefs = await SharedPreferences.getInstance();
           await prefs.setString('local_version', _latestVersion!);
           setState(() => _localVersion = _latestVersion);
        }
        setState(() {
          _isDownloading = false;
          _statusMessage = 'Success! File installed.'; 
          _progress = 1.0;
        });
      }

    } catch (e) {
      _log("Error: $e");
      setState(() {
        _isDownloading = false;
        _statusMessage = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('BromBrom Manager (Pro)'), backgroundColor: Colors.blue[800], foregroundColor: Colors.white),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Section
             Card(
               color: Colors.white,
               child: Padding(
                 padding: const EdgeInsets.all(16.0),
                 child: Column(
                   children: [
                     const Text("Status", style: TextStyle(fontWeight: FontWeight.bold)),
                     const SizedBox(height: 8),
                     Text(_statusMessage, textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.blue[800])),
                     const SizedBox(height: 16),
                     Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Text("Installed: ${_localVersion ?? '-'}"),
                          Text("Latest: ${_latestVersion ?? '-'}"),
                        ],
                     )
                   ],
                 ),
               ),
             ),
             const SizedBox(height: 32),

             // Config Section: Permissions
             if (_safUri == null)
               Column(
                 children: [
                   const Icon(Icons.folder_off, size: 48, color: Colors.orange),
                   const SizedBox(height: 16),
                   const Text(
                     "One-Time Setup Required", 
                     style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)
                   ),
                   const SizedBox(height: 8),
                   const Text(
                     "1. Tap 'Grant Access'\n2. Navigate to 'Android > data > net.osmand > files'\n3. Tap 'Use this Folder'",
                     textAlign: TextAlign.center,
                   ),
                   const SizedBox(height: 16),
                   ElevatedButton(
                     onPressed: _requestSafPermission,
                     style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(20)),
                     child: const Text("GRANT ACCESS TO OSMAND FILES"),
                   ),
                 ],
               ),

             // Active Section: Updates
             if (_safUri != null && _isDownloading)
                LinearProgressIndicator(value: _progress, minHeight: 10),

             if (_safUri != null && !_isDownloading)
               Column(
                 crossAxisAlignment: CrossAxisAlignment.stretch,
                 children: [
                   ElevatedButton.icon(
                     icon: const Icon(Icons.map),
                     label: const Text("UPDATE / INSTALL MAP"),
                     style: ElevatedButton.styleFrom(
                       padding: const EdgeInsets.symmetric(vertical: 18),
                       backgroundColor: _updateAvailable ? Colors.blue : Colors.grey[700],
                       foregroundColor: Colors.white
                     ),
                     onPressed: () => _downloadAndInstall(OBF_FILENAME),
                   ),
                   if (!_updateAvailable)
                     const Padding(padding: EdgeInsets.only(top:8), child: Text("You are up to date.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey))),
                   
                   const SizedBox(height: 24),
                   
                   OutlinedButton.icon(
                     icon: const Icon(Icons.alt_route),
                     label: const Text("INSTALL ROUTING RULES (XML)"),
                     onPressed: () => _downloadAndInstall('routing.xml', isRouting: true),
                   ),
                   const SizedBox(height: 8),
                   const Text(
                     "Note: Installs directly to 'files/'. You may need to move it to 'routing/' if OsmAnd doesn't see it.",
                     textAlign: TextAlign.center, style: TextStyle(fontSize: 10, color: Colors.grey),
                   ),
                 ],
               ),
               
             const Spacer(),
             
             // Debug Logs
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
